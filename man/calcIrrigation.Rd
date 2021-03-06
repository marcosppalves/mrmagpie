% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/calcIrrigation.R
\name{calcIrrigation}
\alias{calcIrrigation}
\title{calcIrrigation}
\usage{
calcIrrigation(
  selectyears = "all",
  version = "LPJmL5",
  climatetype = "CRU_4",
  time = "spline",
  averaging_range = NULL,
  dof = 4,
  harmonize_baseline = FALSE,
  ref_year = NULL,
  rainfedweight = 0.01
)
}
\arguments{
\item{selectyears}{years to be returned}

\item{version}{Switch between LPJmL4 and LPJmL5}

\item{climatetype}{Switch between different climate scenarios (default: "CRU_4")}

\item{time}{Time smoothing: average, spline or raw (default)}

\item{averaging_range}{only specify if time=="average": number of time steps to average}

\item{dof}{only specify if time=="spline": degrees of freedom needed for spline}

\item{harmonize_baseline}{FALSE (default): no harmonization, TRUE: if a baseline is specified here data is harmonized to that baseline (from ref_year on)}

\item{ref_year}{Reference year for harmonization baseline (just specify when harmonize_baseline=TRUE)}

\item{rainfedweight}{For clustering airrig is weighted with cropland_irrigated + rainfedweight * cropland_rainfed (default: 0.01)}
}
\value{
magpie object in cellular resolution
}
\description{
This function extracts irrigation water (airrig: water applied additionally to rainfall) from LPJmL to MAgPIE
}
\examples{
\dontrun{ calcOutput("Irrigation", aggregate = FALSE) }

}
\author{
Felicitas Beier, Abhijeet Mishra
}
