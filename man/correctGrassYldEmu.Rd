% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/correctGrassYldEmu.R
\name{correctGrassYldEmu}
\alias{correctGrassYldEmu}
\title{correctGrassYldEmu}
\usage{
correctGrassYldEmu(x)
}
\arguments{
\item{x}{magpie object provided by the read function}
}
\value{
List of magpie objects.
}
\description{
Correct files related to the training and optimization of the LPJml emulators
}
\examples{

\dontrun{
  readSource("GrassYldEmu", subtype = "GrassYldEmu:20f33a2280.weights", convert="onlycorrect")
}

}
\seealso{
\code{\link{readGrassYldEmu}}
}
\author{
Marcos Alves
}
