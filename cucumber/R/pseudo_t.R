#' Specify a Pseudo-Target within the Student-t Class
#'
#' Create a list of functions to evaluate a pseudo-target in the Student-t class
#' with supplied location, scale, and degrees of freedom. The distribution is optionally
#' truncated to specified bounds (and renormalized).
#'
#'
#' @param loc Numeric scalar giving the location parameter.
#' @param sc Positive numeric scalar giving the scale parameter.
#' @param degf Positive numeric scalar giving the degrees of freedom parameter.
#' @param lb Numeric scalar giving the value of left truncation. Defaults to \code{-Inf}.
#' @param ub Numeric scalar giving the value of right truncation. Defaults to \code{Inf}.
#' @param log_p (Not implemented) Logical: evaluate distribution and quantile functions using the log probability.
#' @param name String appending optional message to the textual name of the distribution.
#' @returns A list with named components:
#'
#'  \code{d}: function to evaluate the density
#'
#'  \code{ld}: function to evaluate the log density
#'
#'  \code{q}: function to evaluate the quantile function
#'
#'  \code{p}: function to evaluate the distribution function
#'
#'  \code{t}: text description of the distribution
#'
#'  \code{loc}: location parameter value
#'
#'  \code{sc}: scale parameter value
#'
#'  \code{degf}: degrees of freedom parameter value
#'
#'  \code{lb}: lower boundary of support
#'
#'  \code{ub}: upper boundary of support
#'
#' @export
#' @examples
#' pseu <- pseudo_t_list(loc = 0.0, sc = 1.0, degf = 1.0, lb = 0.0, ub = Inf) # half Cauchy
#' str(pseu)
#' pseu$d(1.5)
#' pseu$ld(1.5)
#' pseu$p(1.5)
#' pseu$q(0.6256659)
pseudo_t_list <- function(loc, sc, degf, lb = -Inf, ub = Inf, log_p = FALSE, name = NULL) {

  if (!is.null(name)) {
    t <- paste0("t(loc = ", round(loc,2), ", sc = ", round(sc,2), ", degf = ", round(degf), "), ", name)
  } else {
    t <- paste0("t(loc = ", round(loc,2), ", sc = ", round(sc,2), ", degf = ", round(degf), ")")
  }

  if (lb > -Inf || ub < Inf) {
    t <- paste0(t, " I(", lb, " < x < ", ub, ")")
  }


  plb <- pt((lb - loc)/sc, df = degf)
  pub <- pt((ub - loc)/sc, df = degf)
  normc <- pub - plb

  logsc <- log(sc)

  list(d = function(x) {dt((x - loc)/sc, df = degf) / sc * (x > lb & x < ub)},
       ld = function(x) {dt((x - loc)/sc, df = degf, log=TRUE) - logsc + log(x > lb & x < ub)},
       q = function(u, log.p = FALSE) {qt(plb + u*normc, log.p = log.p, df = degf)*sc + loc},
       p = function(x) {(pt((x - loc)/sc, df = degf) - plb) / normc * (x > lb)},
       t = t,
       loc = loc, sc = sc, degf = degf, lb = lb, ub = ub)
}


#' Find the Optimal Pseudo-Target for a Given Target (Student-t Family)
#'
#' Find the optimal pseudo-target in the Student-t family to approximate
#' the given (unnormalized) target. Optimize over a variety of utility functions.
#' Optionally supply samples from the target distribution.
#'
#'
#' @param target List containing functions to evaluate the unnormalized target.
#' Must contain function \code{ld(x)} that evaluates the log-target.
#' @param samples Optional numeric vector providing samples from the target distribution
#' (for use as alternative to \code{target}).
#' @param type String specifying the input type. One of "function", "samples", or "grid".
#' Use of "function" requires \code{target}. Use of "samples" requires \code{samples}.
#' Use of "grid" requires \code{target}. Defaults to "samples".
#' @param degf Numeric vector of degrees of freedom values to try. Defaults to \code{c(1, 5, 20)}.
#' @param lb Numeric scalar giving the value of left truncation. Defaults to \code{-Inf}.
#' @param ub Numeric scalar giving the value of right truncation. Defaults to \code{Inf}.
#' @param nbins Positive integer specifying the number of histogram bins if using "samples" or "grid".
#' Defaults to 100.
#' @param coeffs Positive numeric vector of length two giving relative weights of
#' 1-the base utility (one of AUC or mean slice width) and 2-the penalty for multimodality,
#' measured as the area of water the density could hold. Defaults to \code{c(1.0, 0.0)}.
#' @param tol_opt Positive numeric scalar that passes to \code{reltol} in the call
#' to \code{optim()}. Defaults to \code{1.0e-6}.
#' @param tol_int Positive numeric scalar that passes to \code{abs.tol} in the call to \code{integrate()}.
#' Defaults to \code{1.0e-3}.
#' @param plot Logical for whether to plot a visualization of the transformed target.
#' Defaults to \code{TRUE}.
#' @param verbose Logical for whether to print intermediate steps of optimization.
#' Defaults to \code{FALSE}.
#' @param use_meanSliceWidth Logical for whether the base utility should use
#' Expected Slice Width (if \code{TRUE}; slower) or Area Under the Curve (AUC) if
#' \code{FALSE}. Defaults to \code{FALSE}.
#' @returns A list with named components:
#'
#'  \code{pseu}: a list with functions corresponding to the selected pseudo-target;
#'  output of \code{pseudo_t_list()}.
#'
#'  \code{util}: a list with information about the calculated utility for the selected pseudo-target;
#'  output of \code{utility_shrinkslice()}.
#'
#'  \code{opt}: output of \code{optim()}.
#'
#'  Other outputs repeating inputs.
#' @export
#' @examples
#' (pseu <- opt_t(samples = rnorm(1e3), nbins = 30, coeffs = c(1,0), plot = TRUE,
#'                verbose = FALSE, use_meanSliceWidth = FALSE))
#' (pseu <- opt_t(target = list(ld = function(x) dnorm(x, log = TRUE)),
#'                type = "grid", nbins = 100, coeffs = c(1,0), plot = TRUE, verbose = FALSE,
#'                use_meanSliceWidth = FALSE, tol_opt = 1e-3))
#' (pseu <- opt_t(target = list(ld = function(x) dnorm(x, log = TRUE)),
#'                type = "function", coeffs = c(1,0), plot = TRUE, verbose = TRUE,
#'                use_meanSliceWidth = FALSE, tol_opt = 1e-3, tol_int = 1e-2))
opt_t <- function(target = NULL,
                  samples = NULL,
                  type = "samples", # one of "samples", "grid", "function"
                  degf = c(1, 5, 20),
                  lb = -Inf, ub = Inf,
                  nbins = 100,
                  coeffs = c(1.0, 0.0),
                  tol_opt = 1.0e-6, tol_int = 1.0e-3,
                  plot = TRUE,
                  verbose = FALSE,
                  use_meanSliceWidth = FALSE) {

  if (type %in% c("function", "samples_kde")) {
    x <- NULL
    bins <- NULL
    nbins <- NULL
  } else if (type %in% c("grid", "samples")) {
    x <- seq(1.0e-6, 1.0 - 1.0e-6, length = nbins) # trouble if it doesn't reach far enough into tails
    bins <- c(0.0, x[-c(1, nbins)], 1.0)
  }

  if (is.null(samples)) {
    inits <- c(loc = 0.5, sc = 2.0)
  } else {
    inits <- c(loc = mean(samples), sc = sd(samples))
  }

  get_util <- function(pars, type, x, target, samples, degf, lb, ub, bins, nbins,
                       coeffs, verbose, use_meanSliceWidth) {

    loc <- pars[1]
    sc <- pars[2]

    if (sc <= 0.0) {

      out <- -1.0

    } else {

      pseu <- pseudo_t_list(loc = loc, sc = sc, degf = degf,
                            lb = lb, ub = ub)

      if (verbose) cat("trying", pseu$t, "\n")

      # this function is found in utility_shrinkslice.R; output is the same as utility_shrinkslice()
      out <- util_pseu(pseu = pseu, target = target, samples = samples,
                       type = type, x = x,
                       bins = bins, nbins = nbins,
                       coeffs = coeffs, plot = FALSE,
                       use_meanSliceWidth = use_meanSliceWidth,
                       tol_int = tol_int)

      if (verbose) {
        print(out)
        cat("\n")
      }

      if (out["util"] > 1.0) { # then the result isn't viable. Penalize.
        out["util"] <- -1.0
      }

    }

    out["util"]
  }


  opt <- list()

  for (i in 1:length(degf)) {
    opt[[i]] <- optim(inits, get_util, control = list(fnscale=-1, reltol = tol_opt),
                      type = type,
                      x = x, target = target, samples = samples,
                      degf = degf[i],
                      lb = lb, ub = ub,
                      bins = bins, nbins = nbins,
                      coeffs = coeffs,
                      verbose = verbose,
                      use_meanSliceWidth = use_meanSliceWidth)
  }

  use_indx <- which.max(sapply(opt, function(obj) obj$value))

  pseu <- pseudo_t_list(loc = unname(opt[[use_indx]]$par[1]),
                        sc = unname(opt[[use_indx]]$par[2]),
                        degf = degf[use_indx],
                        lb = lb, ub = ub)

  util <- util_pseu(pseu = pseu, target = target, samples = samples,
                    type = type,
                    x = x,
                    bins = bins, nbins = nbins,
                    coeffs = coeffs,
                    plot = plot,
                    use_meanSliceWidth = use_meanSliceWidth,
                    tol_int = tol_int)

  list(pseu = pseu, util = util, opt = opt[[use_indx]], nbins = nbins, coeffs = coeffs,
       tol_int = tol_int, tol_opt = tol_opt)
}

