% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/cma.R
\name{plot_cma}
\alias{plot_cma}
\title{Plot Simultaneous Confidence Bands from CMA Output}
\usage{
plot_cma(
  data,
  xlab = "Time",
  ylab = "Estimated Mean",
  line_color = "black",
  ci_color = "gray50",
  ci_linetype = "dashed",
  group_label = "Group",
  title = "Simultaneous Confidence Band",
  show_legend = FALSE
)
}
\arguments{
\item{data}{A data frame or tibble containing the results of the \code{cma()} function.
Must include columns: \code{time}, \code{yhat}, \code{scb_low}, and \code{scb_up}.}

\item{xlab}{A character string for the x-axis label. Default is \code{"Time"}.}

\item{ylab}{A character string for the y-axis label. Default is \code{"Estimated Mean"}.}

\item{line_color}{Color for the main estimated curve (\code{yhat}). Default is \code{"black"}.}

\item{ci_color}{Color for the confidence bands (\code{scb_low} and \code{scb_up}). Default is \code{"gray50"}.}

\item{ci_linetype}{Line type for the confidence bands. Default is \code{"dashed"}.}

\item{group_label}{A character label for the color legend. Default is \code{"Group"}.}

\item{title}{A character string for the plot title. Default is \code{"Simultaneous Confidence Band"}.}

\item{show_legend}{Logical. Whether to display the legend. Default is \code{FALSE}.}
}
\value{
A \code{ggplot2} object representing the confidence band plot.
}
\description{
This function visualizes the estimated mean function and simultaneous confidence bands
(SCB) from a CMA result object. It supports customization of colors, line types, axis labels,
and legend display.
}
\examples{

# example using ccds data
data(ccds)
ccds_fpca <- prepare_ccds_fpca(ccds)

fosr_mod <- mgcv::bam(percent_change ~ s(seconds, k=30, bs="cr") +
  s(seconds, by = use, k=30, bs = "cr") +
  s(subject, by = Phi1, bs="re") +
  s(subject, by = Phi2, bs="re")+
  s(subject, by = Phi3, bs="re") +
  s(subject, by = Phi4, bs="re"),
  method = "fREML", data = ccds_fpca, discrete = TRUE)

ccds_cma <- cma(ccds_fpca, fosr_mod, time = "seconds", group_name = "use", group_value = 1,
                subject = "subject")
ccds_cma <- tibble::as_tibble(ccds_cma)
plot_cma(ccds_cma, xlab = "Time (s)", ylab = "Mean",
         line_color = "blue", ci_color = "gray", ci_linetype = "dotted",
         title = "Global SCB for Treatment Group")

}
