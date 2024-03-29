% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/auc_water.R
\name{auc}
\alias{auc}
\title{Area Under the Curve (histogram)}
\usage{
auc(x, y, u = NULL, nbins = 30)
}
\arguments{
\item{x}{Numeric vector of histogram locations. (Not used if \code{u} is supplied).}

\item{y}{Numeric vector of histogram heights OR function evaluating the curve
for a given value of \code{u}.(Not used if \code{u} is supplied).}

\item{u}{Numeric vector of samples supported on unit interval with which to
create histogram (use \code{u = NULL} if \code{x} and \code{y} are supplied).}

\item{nbins}{Number of histogram bins to use (defaults to 30).}
}
\description{
Calculate the histogram approximation to the area under the curve after restricting
the curve to fit within the unit square. Specifically, the highest histogram bar reaches 1 and
the support is the unit interval.
}
\examples{
auc(u = rbeta(1000, 2, 2))
auc(x = runif(1000), y = function(x) {dbeta(x, 2, 2)})
}
