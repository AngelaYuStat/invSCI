% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/regression_outcome_scb.R
\name{SCB_linear_outcome}
\alias{SCB_linear_outcome}
\title{Construct Simultaneous Confidence Bands for a Linear Regression Model}
\usage{
SCB_linear_outcome(
  df_fit,
  model,
  grid_df,
  n_boot = 1000,
  alpha = 0.05,
  grid_df_boot = NULL
)
}
\arguments{
\item{df_fit}{A data frame containing the training design matrix used to fit the linear model.}

\item{model}{A character string representing the formula for the linear model (e.g., \code{"y ~ x1 + x2"}).}

\item{grid_df}{A data frame containing the test set design matrix at which to evaluate the predictions and construct confidence bands.}

\item{n_boot}{Number of bootstrap samples used in the non-parametric bootstrap procedure to generate the empirical distribution. Default is 1000.}

\item{alpha}{Significance level for the confidence band (e.g., 0.05 for 95\% confidence). Default is 0.05.}

\item{grid_df_boot}{An optional data frame specifying the input grid at which predictions are evaluated during bootstrap resampling.
This allows SCBs to be constructed on a denser or alternative set of covariate values if desired.. If NULL, uses \code{grid_df}.}
}
\value{
A data frame with the following columns:
\describe{
\item{scb_low}{Lower bound of the simultaneous confidence band.}
\item{Mean}{Predicted mean response from the fitted model.}
\item{scb_up}{Upper bound of the simultaneous confidence band.}
\item{...}{All columns from \code{grid_df}, representing the prediction grid.}
}
}
\description{
This function fits a linear model and constructs simultaneous confidence bands (SCB)
using a non-parametric bootstrap method for the mean outcome of regression on a fixed test set design matrix
}
\examples{
set.seed(262)
x1 <- rnorm(100)
x2 <- rnorm(100)
epsilon <- rnorm(100,0,sqrt(2))
y <- -1 + x1 + 0.5 * x1^2 - 1.1 * x1^3 - 0.5 * x2 + 0.8 * x2^2 - 1.1 * x2^3 + epsilon
df <- data.frame(x1 = x1, x2 = x2, y = y)
grid <- data.frame(x1 = seq(-1, 1, length.out = 100), x2 = seq(-1, 1, length.out = 100))
model <- "y ~ x1 + I(x1^2) + I(x1^3) + x2 + I(x2^2) + I(x2^3)"
results <- SCB_linear_outcome(df_fit = df, model = model, grid_df = grid)

}
