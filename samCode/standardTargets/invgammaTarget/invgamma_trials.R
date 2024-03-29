# creating the trials for the inverse gamma target
# author: Sam Johnson

source('invgamma_setup.R')

#### Tuning Parameters ####
## starting point ##
x <- c(1)

## stepping out ##
## stepping out metrics to input ##
w <- c(0.5,1,1.5,2,2.5,3,3.5,4,4.5,5,5.5,6,6.5,7,7.5,8,8.5,9,9.5,10)

# creating a data frame with all possible combinations
trials_stepping_out <- expand.grid(samples, x, w) %>%
  dplyr::rename('samples' = 'Var1',
                'x' = 'Var2',
                'w' = 'Var3')

trials_stepping_out <- trials_stepping_out[sample(1:nrow(trials_stepping_out)), ]

save(trials_stepping_out, file = 'input/steppingout.rds')

## gess ##
## gess slice sampling metrics to input ##
mu <- c(0.5, 1, 2)
sigma <- c(0.25, 0.5,1, 2, 3, 4, 5)
df <- c(1, 5, 20)

# creating a data frame with all possible combinations
trials_gess <- expand.grid(samples, x, mu, sigma, df) %>%
  dplyr::rename(
    'samples' = 'Var1',
    'x' = 'Var2',
    'mu' = 'Var3',
    'sigma' = 'Var4',
    'df' = 'Var5'
  )

trials_gess <- trials_gess[sample(1:nrow(trials_gess)), ]

save(trials_gess, file = 'input/gess.rds')

## latent ##
## latent slice sampling metric to input ##
s <- c(3)
rate <- c(0.0005, 0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1, 2)

# creating a data frame with all possible combinations
trials_latent <- expand.grid(samples, x, s, rate) %>%
  dplyr::rename(
    'samples' = 'Var1',
    'x' = 'Var2',
    's' = 'Var3',
    'rate' = 'Var4'
  )

trials_latent <- trials_latent[sample(1:nrow(trials_latent)), ]

save(trials_latent, file = 'input/latent.rds')

## transform ##
### Specialty Scenarios

miscPseudoTargets <- list(
  pseudo_t_list(loc = 0.41, sc = 0.38, degf = 1, lb = 0, name = 'Man'),
  pseudo_t_list(loc = 0.37, sc = 0.44, degf = 1, lb = 0, name = 'Man'),
  pseudo_t_list(loc = 0.33, sc = 0.47, degf = 1, lb = 0, name = 'Man')
)

# getting burn in draws to fit pseudo target
burnin_metrics <- rinvgamma(5e3, shape = 2 , scale = 1)

# fitting the Cauchy
# auto
psuedoFit <- fit_trunc_Cauchy(burnin_metrics, lb = 0)
autoCauchy <- pseudo_t_list(loc = psuedoFit$fit$par[1],sc = psuedoFit$fit$par[2], degf = 1, lb = 0, name = 'Auto')
# laplace
laplaceCauchy <- lapproxt(f = truth$d, init = 1, lb = 0)

testCoeffs <- c(0.0, 0.5, 1.0, 2.0)
testCoeffsDf <- data.frame(c1 = rep(1, length(testCoeffs)), c2 = testCoeffs)

optimSamplesT <- sapply(1:nrow(testCoeffsDf), FUN = \(i) {
  coeffs <- testCoeffsDf[i,]
  coeffs <- c(coeffs[1,1], coeffs[1,2])
  psuedoFit <- opt_t(samples = burnin_metrics, nbins = 30, coeffs = coeffs, lb = 0, type = 'samples', degf = 1)
  temp <- pseudo_t_list(loc = psuedoFit$pseu$loc[[1]],sc = psuedoFit$pseu$sc[[1]], degf = psuedoFit$pseu$degf[[1]], lb = 0,
                        name = paste0('c2:', psuedoFit$coeffs[2],' OS'))
  temp
}, simplify = FALSE)

optimSamplesTAUC <- sapply(1:nrow(testCoeffsDf), FUN = \(i) {
  coeffs <- testCoeffsDf[i,]
  coeffs <- c(coeffs[1,1], coeffs[1,2])
  psuedoFit <- opt_t(samples = burnin_metrics, nbins = 30, coeffs = coeffs, lb = 0, type = 'samples', use_meanSliceWidth = FALSE, degf = 1)
  temp <- pseudo_t_list(loc = psuedoFit$pseu$loc[[1]],sc = psuedoFit$pseu$sc[[1]], degf = psuedoFit$pseu$degf[[1]], lb = 0,
                        name = paste0('c2:', psuedoFit$coeffs[2],' OSAUC'))
  temp
}, simplify = FALSE)

# fit using optim
optimT <- sapply(1:nrow(testCoeffsDf), FUN = \(i) {
  coeffs <- testCoeffsDf[i,]
  coeffs <- c(coeffs[1,1], coeffs[1,2])
  print(coeffs)
  psuedoFit <- opt_t(target = truth, nbins = 30, coeffs = coeffs, lb = 0, type = 'function', degf = 1)
  temp <- pseudo_t_list(loc = psuedoFit$pseu$loc[[1]],sc = psuedoFit$pseu$sc[[1]], degf = psuedoFit$pseu$degf[[1]], lb = 0,
                        name = paste0('c2:', psuedoFit$coeffs[2],' O'))
  temp
}, simplify = FALSE)

# fit using optim
optimTAUC <- sapply(1:nrow(testCoeffsDf), FUN = \(i) {
  coeffs <- testCoeffsDf[i,]
  coeffs <- c(coeffs[1,1], coeffs[1,2])
  psuedoFit <- opt_t(target = truth, nbins = 30, coeffs = coeffs, lb = 0, type = 'function', use_meanSliceWidth = FALSE, degf = 1)
  temp <- pseudo_t_list(loc = psuedoFit$pseu$loc[[1]],sc = psuedoFit$pseu$sc[[1]], degf = psuedoFit$pseu$degf[[1]], lb = 0,
                        name = paste0('c2:', psuedoFit$coeffs[2],' OAUC'))
  temp
}, simplify = FALSE)


## transform tuning parameters ##
log_pdf <- lapply(miscPseudoTargets, \(list) list$ld) |> unlist()

log_pdf_optim <- lapply(optimT, \(list) list$ld) %>% unlist()
log_pdf_optim_auc <- lapply(optimTAUC, \(list) list$ld) %>% unlist()
log_pdf_samples_optim <- lapply(optimSamplesT, \(list) list$ld) |> unlist()
log_pdf_samples_optim_auc <- lapply(optimSamplesTAUC, \(list) list$ld) |> unlist()


log_pdf <- append(log_pdf, list(autoCauchy$ld, laplaceCauchy$ld)) |> append(log_pdf_optim) |> append(log_pdf_samples_optim) |> 
  append(log_pdf_optim_auc) |> append(log_pdf_samples_optim_auc)

inv_cdf <- lapply(miscPseudoTargets, \(list) list$q) |> unlist()

inv_cdf_optim <- lapply(optimT, \(list) list$q) %>% unlist()
inv_cdf_optim_auc <- lapply(optimTAUC, \(list) list$q) %>% unlist()
inv_cdf_samples_optim <- lapply(optimSamplesT, \(list) list$q) |> unlist()
inv_cdf_samples_optim_auc <- lapply(optimSamplesTAUC, \(list) list$q) |> unlist()

inv_cdf <- append(inv_cdf, list(autoCauchy$q, laplaceCauchy$q)) |> append(inv_cdf_optim) |> append(inv_cdf_samples_optim) |> 
  append(inv_cdf_optim_auc) |> append(inv_cdf_samples_optim_auc)

t <- lapply(miscPseudoTargets, \(list) list$t) |> unlist()

t_optim <- lapply(optimT, \(list) list$t) %>% unlist()
t_optim_auc <- lapply(optimTAUC, \(list) list$t) %>% unlist()
t_samples_optim <- lapply(optimSamplesT, \(list) list$t) |> unlist()
t_samples_optim_auc <- lapply(optimSamplesTAUC, \(list) list$t) |> unlist()

t <- c(t, list(autoCauchy$t, laplaceCauchy$t)) |> append(t_optim) |> append(t_samples_optim) |> 
  append(t_optim_auc) |> append(t_samples_optim_auc)


#####

temp_df <- data.frame(log_pdf = matrix(nrow = length(log_pdf), ncol = 1))
temp_df$log_pdf <- log_pdf
temp_df$inv_cdf <- inv_cdf
temp_df$t <- t

# creating a data frame with all possible combinations
trials_transform <- expand.grid(samples, x) %>%
  dplyr::rename('samples' = 'Var1',
                'x' = 'Var2')

trials_transform <-
  sapply(trials_transform, rep.int, times = nrow(temp_df)) %>% data.frame()

transform_parameters <-
  sapply(temp_df, rep.int, times = nrow(trials_transform) / nrow(temp_df)) %>%
  data.frame() %>%
  arrange(inv_cdf)

trials_transform <- cbind(trials_transform, transform_parameters)

trials_transform <- trials_transform[sample(1:nrow(trials_transform)), ]

save(trials_transform, file = 'input/transform.rds')

## randwalk ##
## random walk tuning parameters ##
c <- c(0.25,0.5,1,1.5,2,2.5,3,3.5,4,4.5,5,5.5,6,6.5,7,7.5)

trials_rand_walk <- expand.grid(samples, x, c) %>%
  dplyr::rename('samples' = 'Var1',
                'x' = 'Var2',
                'c' = 'Var3')

trials_rand_walk <- trials_rand_walk[sample(1:nrow(trials_rand_walk)), ]

save(trials_rand_walk, file = 'input/randwalk.rds')