test_that("all S3 methods have reasonable ouputs", {
  fit1 <- brms:::rename_pars(brms:::brmsfit_example1)
  fit2 <- brms:::rename_pars(brms:::brmsfit_example2)
  fit3 <- brms:::rename_pars(brms:::brmsfit_example3)
  fit4 <- brms:::rename_pars(brms:::brmsfit_example4)
  fit5 <- brms:::rename_pars(brms:::brmsfit_example5)
  fit6 <- brms:::rename_pars(brms:::brmsfit_example6)
  
  expect_range <- function(object, lower = -Inf, upper = Inf, ...) {
    testthat::expect_true(all(object >= lower & object <= upper), ...)
  }
  SM <- suppressMessages
  
  # test S3 methods in alphabetical order
  # as.data.frame
  ps <- as.data.frame(fit1)
  expect_true(is(ps, "data.frame"))
  expect_equal(dim(ps), c(nsamples(fit1), length(parnames(fit1))))
  
  # as.matrix
  ps <- as.matrix(fit1)
  expect_true(is(ps, "matrix"))
  expect_equal(dim(ps), c(nsamples(fit1), length(parnames(fit1))))
  
  # as.mcmc
  chains <- fit1$fit@sim$chains
  mc <- as.mcmc(fit1)
  expect_equal(length(mc), chains)
  expect_equal(dim(mc[[1]]), c(nsamples(fit1) / chains, length(parnames(fit1))))
  mc <- as.mcmc(fit1, combine_chains = TRUE)
  expect_equal(dim(mc), c(nsamples(fit1), length(parnames(fit1))))
  # test assumes thin = 1
  expect_equal(dim(as.mcmc(fit1, inc_warmup = TRUE)[[1]]), 
               c(fit1$fit@sim$iter, length(parnames(fit1))))
  
  # coef
  coef1 <- SM(coef(fit1))
  expect_equal(dim(coef1$visit), c(4, 4, 8))
  coef1 <- SM(coef(fit1, summary = FALSE))
  expect_equal(dim(coef1$visit), c(nsamples(fit1), 4, 8))
  coef2 <- SM(coef(fit2))
  expect_equal(dim(coef2$patient), c(59, 4, 4))
  coef4 <- SM(coef(fit4))
  expect_equal(dim(coef4$subject), c(10, 4, 8))
  # deprecated as of brms 1.7.0
  coef1 <- coef(fit1, old = TRUE)
  expect_equal(dim(coef1$visit), c(4, 8))
  coef2 <- coef(fit2, old = TRUE)
  expect_equal(dim(coef2[[2]]), c(59, 2))
  expect_equal(attr(coef2[[1]], "nlpar"), "a")
  coef4 <- coef(fit4, old = TRUE)
  expect_equal(dim(coef4$subject), c(10, 8))
  
  # family
  expect_equal(family(fit1), brmsfamily("student", link = "identity"))
  
  # fitted
  fi <- fitted(fit1)
  expect_equal(dim(fi), c(nobs(fit1), 4))
  expect_equal(colnames(fi), 
               c("Estimate", "Est.Error", "2.5%ile", "97.5%ile"))
  
  newdata <- data.frame(
    Age = c(0, -0.2), visit = c(1, 4), Trt = c(-0.2, 0.5), 
    count = c(20, 13), patient = c(1, 42), Exp = c(2, 4)
  )
  fi <- fitted(fit1, newdata = newdata)
  expect_equal(dim(fi), c(2, 4))
  newdata$visit <- c(1, 6)
  fi <- fitted(fit1, newdata = newdata, 
               allow_new_levels = TRUE)
  expect_equal(dim(fi), c(2, 4))
  
  # fitted values with new_levels
  newdata <- data.frame(
    Age = 0, visit = paste0("a", 1:100), Trt = 0, 
    count = 20, patient = 1, Exp = 2
  )
  fi <- fitted(fit1, newdata = newdata, allow_new_levels = TRUE, 
               sample_new_levels = "old_levels", nsamples = 10)
  expect_equal(dim(fi), c(100, 4))
  fi <- fitted(fit1, newdata = newdata, allow_new_levels = TRUE, 
               sample_new_levels = "gaussian", nsamples = 1)
  expect_equal(dim(fi), c(100, 4))
  
  # fitted values of auxiliary parameters
  newdata <- data.frame(
    Age = 0, visit = c("a", "b"), Trt = 0, 
    count = 20, patient = 1, Exp = 2
  )
  fi <- fitted(fit1, auxpar = "sigma")
  expect_equal(dim(fi), c(nobs(fit1), 4))
  expect_true(all(fi > 0))
  fi_lin <- fitted(fit1, auxpar = "sigma", scale = "linear")
  expect_equal(dim(fi_lin), c(nobs(fit1), 4))
  expect_true(!isTRUE(all.equal(fi, fi_lin)))
  expect_error(fitted(fit1, auxpar = "inv"),
               "Invalid argument 'auxpar'")
  expect_error(fitted(fit1, auxpar = "nu"),
               "Auxiliary parameter 'nu' was not predicted")

  fi <- fitted(fit2)
  expect_equal(dim(fi), c(nobs(fit2), 4))
  fi <- fitted(fit2, newdata = newdata,
               allow_new_levels = TRUE)
  expect_equal(dim(fi), c(2, 4))
  
  fi <- fitted(fit4)
  expect_equal(dim(fi), c(nobs(fit4), 4, 4))
  fi <- fitted(fit4, newdata = fit4$data[1, ])
  expect_equal(dim(fi), c(1, 4, 4))
  
  fi <- fitted(fit5)
  expect_equal(dim(fi), c(nobs(fit5), 4))
  
  fi <- fitted(fit6)
  expect_equal(dim(fi), c(nobs(fit6), 4))
  
  # fixef
  fixef1 <- SM(fixef(fit1))
  expect_equal(rownames(fixef1), 
    c("Intercept", "sigma_Intercept", "Trt", "Age", 
      "Trt:Age", "sAge_1", "sigma_Trt", "Exp")
  )
  # deprecated as of brms 1.7.0
  fixef1 <- fixef(fit1, old = TRUE, estimate = c("mean", "sd"))  
  expect_equal(rownames(fixef1), 
   c("Intercept", "sigma_Intercept", "Trt", "Age", 
     "Trt:Age", "sAge_1", "sigma_Trt", "Exp")
  )
  expect_equal(colnames(fixef1), c("mean", "sd"))
  fixef2 <- fixef(fit2, estimate = c("median", "quantile"), 
                  probs = c(0.05, 0.95), old = TRUE)
  expect_equal(rownames(fixef2), 
    c("a_Intercept", "a_Age", "b_Intercept", "b_Age")
  )
  expect_equal(colnames(fixef2), c("median", "5%", "95%"))
  
  # formula
  expect_equal(formula(fit1)$formula, 
    count ~ Trt * Age + mono(Exp) + s(Age) + offset(Age) + (1 + Trt | visit))
  
  # hypothesis
  hyp <- hypothesis(fit1, c("Intercept > Trt", "Trt:Age = -1"))
  expect_equal(dim(hyp$hypothesis), c(2, 6))
  expect_output(print(hyp), "(Intercept)-(Trt) > 0", fixed = TRUE)
  expect_true(is(plot(hyp, plot = FALSE)[[1]], "ggplot"))
  
  hyp <- hypothesis(fit1, "Intercept = 0", class = "sd", group = "visit")
  expect_true(is.numeric(hyp$hypothesis$Evid.Ratio[1]))
  expect_output(print(hyp), "class sd_visit:", fixed = TRUE)
  expect_true(is(plot(hyp, ignore_prior = TRUE, plot = FALSE)[[1]], "ggplot"))
  
  hyp <- hypothesis(fit1, "0 > r_visit[4,Intercept]", class = "", alpha = 0.01)
  expect_equal(dim(hyp$hypothesis), c(1, 6))
  expect_output(print(hyp, chars = NULL), "r_visit[4,Intercept]", fixed = TRUE)
  expect_output(print(hyp), "l-99% CI", fixed = TRUE)
  
  expect_error(hypothesis(fit1, "Intercept > x"), fixed = TRUE,
               "cannot be found in the model: \n'b_x'")
  expect_error(hypothesis(fit1, 1),
               "Argument 'hypothesis' must be a character vector")
  expect_error(hypothesis(fit2, "b_Age = 0", alpha = 2),
               "Argument 'alpha' must be a single value in [0,1]",
               fixed = TRUE)
  expect_error(hypothesis(fit3, "b_Age x 0"),
               "Every hypothesis must be of the form 'left (= OR < OR >) right'",
               fixed = TRUE)
  
  # test hypothesis.default method
  hyp <- hypothesis(as.data.frame(fit3), "bme_meAgeAgeSD > sigma")
  expect_equal(dim(hyp$hypothesis), c(1, 6))
  hyp <- hypothesis(fit3$fit, "bme_meAgeAgeSD > sigma")
  expect_equal(dim(hyp$hypothesis), c(1, 6))
  
  # omit launch_shiny
  
  # log_lik
  expect_equal(dim(log_lik(fit1)), c(nsamples(fit1), nobs(fit1)))
  expect_equal(dim(log_lik(fit2)), c(nsamples(fit2), nobs(fit2)))
  expect_equal(log_lik(fit1), logLik(fit1))
  
  # LOO
  loo1 <- SW(LOO(fit1, cores = 1))
  expect_true(is.numeric(loo1[["looic"]]))
  expect_true(loo1[["se_looic"]] > 0)
  expect_output(print(loo1), "LOOIC")
  expect_equal(loo1, SW(loo(fit1, cores = 1)))
  
  loo_compare1 <- SW(LOO(fit1, fit1, cores = 1))
  expect_equal(length(loo_compare1), 3)
  expect_equal(dim(loo_compare1$ic_diffs__), c(1, 2))
  expect_output(print(loo_compare1), "fit1 - fit1")
  
  loo_compare2 <- SW(LOO(fit1, fit1, fit1, cores = 1))
  expect_equal(length(loo_compare2), 4)
  expect_equal(dim(loo_compare2$ic_diffs__), c(3, 2))
  
  loo2 <- SW(LOO(fit2, cores = 1))
  expect_true(is.numeric(loo2[["looic"]]))
  
  loo3 <- SW(LOO(fit3, cores = 1))
  expect_true(is.numeric(loo3[["looic"]]))
  loo3 <- SW(LOO(fit3, pointwise = TRUE, cores = 1))
  expect_true(is.numeric(loo3[["looic"]]))
  
  loo4 <- SW(LOO(fit4, cores = 1))
  expect_true(is.numeric(loo4[["looic"]]))
  
  loo5 <- SW(LOO(fit5, cores = 1))
  expect_true(is.numeric(loo5[["looic"]]))
  
  loo6_1 <- SW(LOO(fit6, cores = 1))
  expect_true(is.numeric(loo6_1[["looic"]]))
  loo6_2 <- SW(LOO(fit6, cores = 1, newdata = fit6$data[1:30, ]))
  expect_true(is.numeric(loo6_2[["looic"]]))
  loo_compare <- compare_ic(loo6_1, loo6_2)
  expect_range(loo_compare$ic_diffs__[1, 1], -1, 1)

  # loo_linpred
  llp <- SW(loo_linpred(fit1))
  expect_equal(length(llp), nobs(fit1))
  llp2 <- SW(loo::psislw(-log_lik(fit1), cores = 1))
  llp2 <- loo_linpred(fit1, lw = llp2$lw_smooth)
  expect_equal(llp, llp2)
  
  expect_error(loo_linpred(fit4), "Method 'loo_linpred'")
  llp <- SW(loo_linpred(fit2, scale = "response", type = "var"))
  expect_equal(length(llp), nobs(fit2))
  
  # loo_predict
  llp <- SW(loo_predict(fit1))
  expect_equal(length(llp), nobs(fit1))
  llp <- SW(loo_predict(
    fit1, newdata = newdata, 
    type = "quantile", probs = c(0.25, 0.75),
    allow_new_levels = TRUE
  ))
  expect_equal(dim(llp), c(2, nrow(newdata)))
  llp <- SW(loo_predict(fit4))
  expect_equal(length(llp), nobs(fit4))
  
  # loo_predictive_interval
  llp <- SW(loo_predictive_interval(fit3, pointwise = TRUE))
  expect_equal(dim(llp), c(nobs(fit3), 2))
  
  # marginal_effects
  me <- marginal_effects(fit1)
  expect_equal(nrow(me[[2]]), 100)
  meplot <- plot(me, points = TRUE, rug = TRUE, 
                 ask = FALSE, plot = FALSE)
  expect_true(is(meplot[[1]], "ggplot"))
  
  me <- marginal_effects(fit1, "Trt", select_points = 0.1)
  expect_lt(nrow(attr(me[[1]], "points")), nobs(fit1))
  
  me <- marginal_effects(fit1, "Trt:Age", surface = TRUE, 
                         resolution = 15, too_far = 0.2)
  meplot <- plot(me, plot = FALSE)
  expect_true(is(meplot[[1]], "ggplot"))
  meplot <- plot(me, stype = "raster", plot = FALSE)
  expect_true(is(meplot[[1]], "ggplot"))
  
  me <- marginal_effects(fit1, "Trt", spaghetti = TRUE, nsamples = 10)
  expect_equal(nrow(attr(me$Trt, "spaghetti")), 1000)
  meplot <- plot(me, plot = FALSE)
  expect_true(is(meplot[[1]], "ggplot"))
  expect_error(
    marginal_effects(fit1, "Trt", spaghetti = TRUE, surface = TRUE),
    "Cannot use 'spaghetti' and 'surface' at the same time"
  )
  
  mdata = data.frame(
    Age = c(-0.3, 0, 0.3), 
    count = c(10, 20, 30), 
    Exp = c(1, 3, 5)
  )
  exp_nrow <- nrow(mdata) * 100
  me <- marginal_effects(fit1, effects = "Trt", conditions = mdata)
  expect_equal(nrow(me[[1]]), exp_nrow)
  
  mdata$visit <- 1:3
  me <- marginal_effects(fit1, re_formula = NULL, conditions = mdata)
  expect_equal(nrow(me[[1]]), exp_nrow)
  
  me <- marginal_effects(
    fit1, "Trt:Age", int_conditions = list(Age = rnorm(5))
  )
  expect_equal(nrow(me[[1]]), 500)
  me <- marginal_effects(
    fit1, "Trt:Age", int_conditions = list(Age = quantile)
  )
  expect_equal(nrow(me[[1]]), 500)
  
  expect_error(marginal_effects(fit1, effects = "Trtc"), 
               "All specified effects are invalid for this model")
  expect_warning(marginal_effects(fit1, effects = c("Trtc", "Trt")), 
                 "Some specified effects are invalid for this model")
  expect_error(marginal_effects(fit1, effects = "Trtc:a:b"), 
               "please use the 'conditions' argument")
  
  mdata$visit <- NULL
  mdata$patient <- 1
  expect_equal(nrow(marginal_effects(fit2)[[2]]), 100)
  me <- marginal_effects(fit2, re_formula = NULL, conditions = mdata)
  expect_equal(nrow(me[[1]]), exp_nrow)
  
  expect_warning(me4 <- marginal_effects(fit4),
                 "Predictions are treated as continuous variables")
  expect_true(is(me4, "brmsMarginalEffects"))
  
  me5 <- marginal_effects(fit5)
  expect_true(is(me5, "brmsMarginalEffects"))
  
  me6 <- marginal_effects(fit6, nsamples = 100)
  expect_true(is(me6, "brmsMarginalEffects"))
  
  # marginal_smooths
  ms <- marginal_smooths(fit1)
  expect_equal(nrow(ms[[1]]), 100)
  expect_true(is(ms, "brmsMarginalEffects"))
  
  ms <- marginal_smooths(fit1, spaghetti = TRUE, nsamples = 10)
  expect_equal(nrow(attr(ms[[1]], "spaghetti")), 1000)
  
  expect_error(marginal_smooths(fit1, smooths = "s3"),
               "No valid smooth terms found in the model")
  expect_error(marginal_smooths(fit2),
               "No valid smooth terms found in the model")
  
  # model.frame
  expect_equal(model.frame(fit1), fit1$data)
  
  # ngrps
  expect_equal(ngrps(fit1), list(visit = 4))
  expect_equal(ngrps(fit2), list(patient = 59))
  
  # nobs
  expect_equal(nobs(fit1), nrow(epilepsy))
  
  # nsamples
  expect_equal(nsamples(fit1), 100)
  expect_equal(nsamples(fit1, subset = 10:1), 10)
  expect_equal(nsamples(fit1, incl_warmup = TRUE), 400)
  
  # parnames 
  expect_equal(parnames(fit1)[c(1, 8, 9, 13, 15, 17, 27, 35, 38, 46, 47)],
               c("b_Intercept", "bmo_Exp", "ar[1]", "cor_visit__Intercept__Trt", 
                 "nu", "simplex_Exp[2]", "r_visit[4,Trt]", "s_sAge_1[8]", 
                 "prior_sd_visit", "prior_cor_visit", "lp__"))
  expect_equal(parnames(fit2)[c(1, 4, 6, 7, 9, 71, 129)],
               c("b_a_Intercept", "b_b_Age", "sd_patient__b_Intercept",
                 "cor_patient__a_Intercept__b_Intercept", 
                 "r_patient__a[1,Intercept]", "r_patient__b[4,Intercept]",
                 "prior_b_a"))
  expect_true(all(c("sdgp_gpAge", "lscale_gpAge") %in% parnames(fit6)))
  
  # plot tested in tests.plots.R
  
  # posterior_samples
  ps <- posterior_samples(fit1)
  expect_equal(dim(ps), c(nsamples(fit1), length(parnames(fit1))))
  expect_equal(names(ps), parnames(fit1))
  expect_equal(names(posterior_samples(fit1, pars = "^b_")),
               c("b_Intercept", "b_sigma_Intercept", "b_Trt", 
                 "b_Age", "b_Trt:Age", "b_sAge_1", "b_sigma_Trt"))
  
  # test default method
  ps <- posterior_samples(fit1$fit, "b_Intercept")
  expect_equal(dim(ps), c(nsamples(fit1), 1))
  
  # posterior_predict
  expect_equal(dim(posterior_predict(fit1)), 
               c(nsamples(fit1), nobs(fit1)))
  
  # pp_check
  expect_true(is(pp_check(fit1), "ggplot"))
  expect_true(is(pp_check(fit1, newdata = fit1$data[1:100, ]), "ggplot"))
  expect_true(is(pp_check(fit1, "stat", nsamples = 5), "ggplot"))
  expect_true(is(pp_check(fit1, "error_binned"), "ggplot"))
  pp <- pp_check(fit1, "ribbon_grouped", group = "visit", x = "Age")
  expect_true(is(pp, "ggplot"))
  pp <- pp_check(fit1, type = "violin_grouped", 
                 group = "visit", newdata = fit1$data[1:100, ])
  expect_true(is(pp, "ggplot"))
  
  pp <- SW(pp_check(fit1, type = "loo_pit", loo_args = list(cores = 1)))
  expect_true(is(pp, "ggplot"))
  lw <- SW(loo::psislw(-log_lik(fit1), cores = 1)$lw_smooth)
  # not getting warnings implies that the precomputed lw is used
  pp <- pp_check(fit1, type = "loo_intervals", lw = lw)
  expect_true(is(pp, "ggplot"))
  
  expect_true(is(pp_check(fit3), "ggplot"))
  expect_true(is(pp_check(fit2, "ribbon", x = "Trt"), "ggplot"))
  expect_error(pp_check(fit2, "ribbon", x = "x"),
               "Variable 'x' is not a valid variable")
  expect_error(pp_check(fit1, "wrong_type"))
  expect_error(pp_check(fit2, "violin_grouped"), "group")
  expect_error(pp_check(fit1, "stat_grouped", group = "g"),
               "not a valid grouping factor")
  expect_true(is(pp_check(fit4), "ggplot"))
  expect_true(is(pp_check(fit5), "ggplot"))
  expect_error(pp_check(fit4, "error_binned"),
               "Type 'error_binned' is not available")
  
  # pp_mixture
  expect_equal(dim(pp_mixture(fit5)), c(nobs(fit5), 4, 2))
  expect_error(pp_mixture(fit1), 
    "Method 'pp_mixture' can only be applied on mixture models"
  )
  
  # predict
  pred <- predict(fit1)
  expect_equal(dim(pred), c(nobs(fit1), 4))
  expect_equal(colnames(pred), 
               c("Estimate", "Est.Error", "2.5%ile", "97.5%ile"))
  pred <- predict(fit1, nsamples = 10, probs = c(0.2, 0.5, 0.8))
  expect_equal(dim(pred), c(nobs(fit1), 5))
  
  newdata <- data.frame(Age = c(0, -0.2), visit = c(1, 4),
                        Trt = c(-0.2, 0.5), count = c(2, 10),
                        patient = c(1, 42), Exp = c(1, 2))
  pred <- predict(fit1, newdata = newdata)
  expect_equal(dim(pred), c(2, 4))
  
  newdata$visit <- c(1, 6)
  pred <- predict(fit1, newdata = newdata, 
                  allow_new_levels = TRUE)
  expect_equal(dim(pred), c(2, 4))
  
  pred <- predict(fit2)
  expect_equal(dim(pred), c(nobs(fit2), 4))
  
  pred <- predict(fit2, newdata = newdata, 
                  allow_new_levels = TRUE)
  expect_equal(dim(pred), c(2, 4))
  
  pred <- predict(fit4)
  expect_equal(dim(pred), c(nobs(fit4), 4))
  expect_equal(colnames(pred), paste0("P(Y = ", 1:4, ")"))
  
  pred <- predict(fit5)
  expect_equal(dim(pred), c(nobs(fit5), 4))
  
  # check if grouping factors with a single level are accepted
  newdata$patient <- factor(2)
  pred <- predict(fit2, newdata = newdata)
  expect_equal(dim(pred), c(2, 4))
  
  # predictive error
  expect_equal(dim(predictive_error(fit1)), 
               c(nsamples(fit1), nobs(fit1)))
  
  # print
  expect_output(SW(print(fit1)), "Group-Level Effects:")
  
  # prior_samples
  prs1 <- prior_samples(fit1)
  prior_names <- c("sds_sAge_1", "nu", "sd_visit", "b", "bmo", 
                   paste0("simplex_Exp[", 1:4, "]"), "b_sigma",
                   "cor_visit")
  expect_equal(dimnames(prs1),
               list(as.character(1:nsamples(fit1)), prior_names))
  
  prs2 <- prior_samples(fit1, pars = "b_Trt")
  expect_equal(dimnames(prs2), list(as.character(1:nsamples(fit1)), "b_Trt"))
  expect_equal(sort(prs1$b), sort(prs2$b_Trt))
  
  # test default method
  prs <- prior_samples(fit1$fit, pars = "^sd_visit")
  expect_equal(names(prs), "prior_sd_visit")
  
  # prior_summary
  expect_true(is(prior_summary(fit1), "brmsprior"))
  
  # ranef
  ranef1 <- SM(ranef(fit1))
  expect_equal(dim(ranef1$visit), c(4, 4, 2))
  
  ranef2 <- SM(ranef(fit2, summary = FALSE))
  expect_equal(dim(ranef2$patient), c(nsamples(fit2), 59, 2))
  
  # deprecated as of brms 1.7.0
  ranef1 <- ranef(fit1, estimate = "median", var = TRUE, old = TRUE)
  expect_equal(dim(ranef1$visit), c(4, 2))
  expect_equal(dim(attr(ranef1$visit, "var")), c(2, 2, 4))
  
  ranef2 <- ranef(fit2, estimate = "mean", var = TRUE, old = TRUE)
  expect_equal(dim(ranef2[[1]]), c(59, 1))
  expect_equal(dim(attr(ranef2[[1]], "var")), c(1, 1, 59))
  
  # residuals
  res1 <- residuals(fit1, type = "pearson", probs = c(0.65))
  expect_equal(dim(res1), c(nobs(fit1), 3))
  newdata <- cbind(epilepsy[1:10, ], Exp = rep(1:5, 2))
  res2 <- residuals(fit1, newdata = newdata)
  expect_equal(dim(res2), c(10, 4))
  newdata$visit <- rep(1:5, 2)
  
  res3 <- residuals(fit1, newdata = newdata,
                    allow_new_levels = TRUE)
  expect_equal(dim(res3), c(10, 4))
  
  res4 <- residuals(fit2)
  expect_equal(dim(res4), c(nobs(fit2), 4))
  
  expect_error(residuals(fit4), 
               "Residuals not implemented for family 'sratio'")
  
  # stancode
  expect_true(is.character(stancode(fit1)))
  expect_output(print(stancode(fit1)), "generated quantities")
  
  # standata
  expect_equal(names(standata(fit1)),
               c("N", "Y", "nb_1", "knots_1", "Zs_1_1", "K", "X", 
                 "Kmo", "Xmo", "Jmo", "con_simplex_1", "Z_1_1", "Z_1_2", 
                 "offset", "K_sigma", "X_sigma", "J_1", "N_1", "M_1", 
                 "NC_1", "Kar", "Kma", "J_lag", "prior_only"))
  expect_equal(names(standata(fit2)),
               c("N", "Y", "C_1", "K_a", "X_a", "Z_1_a_1",
                 "K_b", "X_b", "Z_1_b_2", "J_1", "N_1", "M_1",
                 "NC_1", "weights", "prior_only"))
  
  # stanplot tested in tests.plots.R
  # summary
  summary1 <- SW(summary(fit1, waic = TRUE, priors = TRUE))
  expect_true(is.numeric(summary1$fixed))
  expect_equal(rownames(summary1$fixed), 
               c("Intercept", "sigma_Intercept", "Trt", "Age", 
                 "Trt:Age", "sAge_1", "sigma_Trt", "Exp"))
  expect_equal(colnames(summary1$fixed), 
               c("Estimate", "Est.Error", "l-95% CI", 
                 "u-95% CI", "Eff.Sample", "Rhat"))
  expect_equal(rownames(summary1$random$visit), 
               c("sd(Intercept)", "sd(Trt)", "cor(Intercept,Trt)"))
  expect_true(is.numeric(summary1$waic))
  expect_output(print(summary1), "Population-Level Effects:")
  expect_output(print(summary1), "Priors:")
  
  summary5 <- SW(summary(fit5, waic = TRUE))
  expect_output(print(summary5), "sigma1")
  expect_output(print(summary5), "theta1")
  
  # update
  # do not actually refit the model as is causes CRAN checks to fail
  up <- update(fit1, testmode = TRUE)
  expect_true(is(up, "brmsfit"))
  new_data <- data.frame(Age = rnorm(18), visit = rep(c(3, 2, 4), 6),
                         Trt = rep(c(0, 0.5, -0.5), 6), 
                         count = rep(c(5, 17, 28), 6),
                         patient = 1, Exp = 4)
  
  up <- update(fit1, newdata = new_data, ranef = FALSE, testmode = TRUE)
  expect_true(is(up, "brmsfit"))
  expect_equal(up$data.name, "new_data")
  expect_equal(attr(up$ranef, "levels")$visit, c("2", "3", "4"))
  expect_true("r_1" %in% up$exclude)
  expect_error(update(fit1, data = new_data), "use argument 'newdata'")
  
  up <- update(fit1, formula = ~ . + I(exp(Trt)), testmode = TRUE,
               prior = set_prior("normal(0,10)"))
  expect_true(is(up, "brmsfit"))
  up <- update(fit1, ~ . - Trt + factor(Trt),  testmode = TRUE)
  expect_true(is(up, "brmsfit"))
  
  up <- update(fit1, formula = ~ . + I(exp(Trt)), newdata = new_data,
               sample_prior = FALSE, testmode = TRUE)
  expect_true(is(up, "brmsfit"))
  expect_error(update(fit1, formula. = ~ . + wrong_var),
               "New variables found: 'wrong_var'")
  
  up <- update(fit1, save_ranef = FALSE, testmode = TRUE)
  expect_true("r_1_1" %in% up$exclude)
  up <- update(fit3, save_mevars = FALSE, testmode = TRUE)
  expect_true("Xme_1" %in% up$exclude)
  
  up <- update(fit2, algorithm = "fullrank", testmode = TRUE)
  expect_equal(up$algorithm, "fullrank")
  up <- update(fit2, formula. = bf(. ~ ., a + b ~ 1, nl = TRUE), 
               testmode = TRUE)
  expect_true(is(up, "brmsfit"))
  up <- update(fit2, formula. = count ~ a + b, testmode = TRUE)
  expect_true(is(up, "brmsfit"))
  up <- update(fit3, family = acat(), testmode = TRUE)
  expect_true(is(up, "brmsfit"))
  up <- update(fit3, bf(~., family = acat()), testmode = TRUE)
  expect_true(is(up, "brmsfit"))
  
  # VarCorr
  vc <- SM(VarCorr(fit1))
  expect_equal(names(vc), c("visit"))
  Names <- c("Intercept", "Trt")
  expect_equal(dimnames(vc$visit$cov)[c(1, 3)], list(Names, Names))
  vc <- SM(VarCorr(fit2))
  expect_equal(names(vc), c("patient"))
  expect_equal(dim(vc$patient$cor), c(2, 4, 2))
  vc <- SM(VarCorr(fit2, summary = FALSE))
  expect_equal(dim(vc$patient$cor), c(nsamples(fit2), 2, 2))
  
  # deprecated as of brms 1.7.0
  vc <- VarCorr(fit1, old = TRUE)
  expect_equal(names(vc), c("visit"))
  Names <- c("Intercept", "Trt")
  expect_equivalent(dimnames(vc$visit$cov$mean), list(Names, Names))
  expect_output(print(vc), "visit")
  data_vc <- as.data.frame(vc)
  expect_equal(dim(data_vc), c(2, 7))
  expect_equal(names(data_vc), 
    c("Estimate", "Group", "Name", "Std.Dev", "Cor", "Cov", "Cov")
  )
  vc <- VarCorr(fit2, old = TRUE)
  expect_equal(names(vc), c("patient"))
  data_vc <- as.data.frame(vc)
  expect_equal(dim(data_vc), c(2, 7))
  
  # vcov
  expect_equal(dim(vcov(fit1)), c(8, 8))
  expect_equal(dim(vcov(fit1, cor = TRUE)), c(8, 8))
  
  # WAIC
  waic1 <- SW(WAIC(fit1))
  expect_true(is.numeric(waic1[["waic"]]))
  expect_true(is.numeric(waic1[["se_waic"]]))
  expect_equal(waic1, SW(waic(fit1)))
  
  fit1 <- SW(add_ic(fit1, "waic"))
  expect_equal(WAIC(fit1), fit1$waic)
  
  waic_compare <- SW(WAIC(fit1, fit1))
  expect_equal(length(waic_compare), 3)
  expect_equal(dim(waic_compare$ic_diffs__), c(1, 2))
  waic2 <- SW(WAIC(fit2))
  expect_true(is.numeric(waic2[["waic"]]))
  waic_pointwise <- SW(WAIC(fit2, pointwise = TRUE))
  expect_equal(waic2, waic_pointwise)
  expect_warning(WAIC(fit1, fit2), "Model comparisons are likely invalid")
  waic4 <- SW(WAIC(fit4))
  expect_true(is.numeric(waic4[["waic"]]))
  
  # test diagnostic convenience functions
  expect_true(is(log_posterior(fit1), "data.frame"))
  expect_true(is(nuts_params(fit1), "data.frame"))
  expect_true(is(rhat(fit1), "numeric"))
  expect_true(is(neff_ratio(fit1), "numeric"))
  
  # test fix of issue #214
  expect_true(is.null(attr(fit1$data$patient, "contrasts")))
})
