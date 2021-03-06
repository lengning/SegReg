% Generated by roxygen2 (4.1.1): do not edit by hand
% Please edit documentation in R/fit.seg.R
\name{fit.seg}
\alias{fit.seg}
\title{segmented regression on a gene}
\usage{
fit.seg(data, g.in, maxk=5, t.vect=NULL, min.num.in.seg=5, pvalcut=.1,
               cutdiff=.1, num.try=100,keepfit=FALSE)
}
\arguments{
\item{data}{normalized expression measure. Rows are genes and columns are samples. The data matrix is expected to be normalized.}

\item{g.in}{name of the gene of interest. The gene name should be in the row names of the input data matrix.}

\item{maxk}{max number of breakpoints to consider.
For each gene, the function will fit maxk+1 models containing 0->maxk breakpoints
(1->(maxk+1)) segments. The model with highest adjusted r value will be selected.}

\item{t.vect}{a numerical vector indicates time points. If it si NULL (default), the time will be assumed to be 1:N in which N is number of samples.}

\item{min.num.in.seg}{min number of samples within a segment}

\item{pvalcut}{p value cutoff. If the p value of a segment is greater than pvalcut,
this segment will be called as 'no change'}

\item{cutdiff}{default is 0.1. if the difference between r_adj from the k+1 breakpoint model
and the r_adj from the k breakpoint model is less than cutdiff, the optimal number
of breakpoint will be set as k instead of k+1}

\item{num.try}{number of different seeds to try. If all num.try runs fails,
linear regression results will be returned (which represents one segment case).}

\item{keepfit}{whether keep the fitted object}
}
\value{
id.sign: direction of each sample; -1: down, 0: no change, 1: up
slp: fitted slopes, slp.sign: sign of fitted slopes, slp.pval: p value of each segment,
bp: estimated breakpoints, fitted: fitted values radj: adjusted r value of the model
fit: fit object
}
\description{
segmented regression on a gene
}
\examples{
d1 <- rbind(c(rep(1,50),1:50), c(100:1))
rownames(d1) <- c("g1","g2")
fit.seg(d1, "g1")
}
\author{
Ning Leng
}

