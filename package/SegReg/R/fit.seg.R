#' @title segmented regression on a gene
#' @usage fit.seg(data, g.in, maxk=5, t.vect=NULL, min.num.in.seg=5, pvalcut=.1,
#'                cutdiff=.1, num.try=100,keepfit=FALSE)
#' @param data normalized expression measure. Rows are genes and columns are samples. The data matrix is expected to be normalized.
#' @param g.in name of the gene of interest. The gene name should be in the row names of the input data matrix.
#' @param maxk max number of breakpoints to consider. 
#' For each gene, the function will fit maxk+1 models containing 0->maxk breakpoints
#' (1->(maxk+1)) segments. The model with highest adjusted r value will be selected.
#' @param t.vect a numerical vector indicates time points. If it si NULL (default), the time will be assumed to be 1:N in which N is number of samples.
#' @param min.num.in.seg min number of samples within a segment
#' @param pvalcut p value cutoff. If the p value of a segment is greater than pvalcut,
#' this segment will be called as 'no change'
#' @param cutdiff default is 0.1. if the difference between r_adj from the k+1 breakpoint model
#' and the r_adj from the k breakpoint model is less than cutdiff, the optimal number
#' of breakpoint will be set as k instead of k+1
#' @param num.try number of different seeds to try. If all num.try runs fails,
#' linear regression results will be returned (which represents one segment case).
#' @param keepfit whether keep the fitted object
#' @return id.sign: direction of each sample; -1: down, 0: no change, 1: up
#' slp: fitted slopes, slp.sign: sign of fitted slopes, slp.pval: p value of each segment, 
#' bp: estimated breakpoints, fitted: fitted values radj: adjusted r value of the model
#' fit: fit object
#' @examples d1 <- rbind(c(rep(1,50),1:50), c(100:1))
#' rownames(d1) <- c("g1","g2")
#' fit.seg(d1, "g1")
#' @author Ning Leng
###################
# fit segmented regression for each gene
# the optimal k is the last one whose Radj is > last one + 0.1
# search from 1 to 5 breakpoints
###################
fit.seg <- function(data, g.in, maxk=5, t.vect=NULL,min.num.in.seg=5, pvalcut=.1, 
										cutdiff=.1, num.try=100,keepfit=FALSE){
data.norm <- data	
if(length(g.in)!=1)stop("only one gene should be considered!")
if(!g.in%in%rownames(data)) stop("gene name is not in row names of expressiopn matrix!")
library(segmented)
t.use <- 1:ncol(data.norm)
if(!is.null(t.vect))t.use <- t.vect
t.l <- ncol(data.norm)
step.r <- c(1:maxk)
dat.tmp <- data.norm[g.in,]
seed.use <- 1

# start with lm without bp
lm1 <- lm(dat.tmp ~ t.use)
lm.radj <- summary(lm1)$adj.r.squared
lm.slp <- coef(lm1)[2]
lm.fit <- fitted.values(lm1)
lm.pval <- coef(summary(lm1))[2,4]
lm.sign <- ifelse(lm.slp>0,1,-1)
lm.sign[which(lm.pval>pvalcut)] <- 0
lm.id.sign <- rep(lm.sign, length(t.use))

fit.l.0 <- sapply(1:length(step.r), function(j){
  i <- step.r[j]
  lmseg.try <- suppressMessages(try(segmented(lm1, seg.Z = ~t.use, psi = round(seq(1,t.l, length.out=i+2)[2:(i+1)]), control=seg.control(seed=seed.use)),silent=T))
  seed.use2 <- seed.use 
  while("try-error"%in%class(lmseg.try)& seed.use2<=num.try){
    seed.use2 <- seed.use2 + 1
    lmseg.try <- suppressMessages(try(segmented(lm1, seg.Z = ~t.use, psi = round(seq(1,t.l, length.out=i+2)[2:(i+1)]),control=seg.control(seed=seed.use2)),silent=T))
}
  out <- lmseg.try
},simplify=F)

isna <- which(sapply(fit.l.0, function(i)"try-error"%in%class(i)))

if(length(isna)==maxk){
	out <- list(id.sign=lm.id.sign, slp=lm.slp, slp.sign=lm.sign, slp.pval=lm.pval, 
		bp=NA, fitted=lm.fit, radj=lm.radj,fit=lm1)
	if(keepfit==FALSE)out <- out[1:7]
	return(out) 
	# if it is not solved in 100 trys then return lm results (if num.try=100)
	break
}


fit.l <- fit.l.0
if(length(isna)>0){ # if one of step.r cant be fitted..
  fit.l <- fit.l.0[-isna]
  step.r <- step.r[-isna]
}

slp.l <- sapply(fit.l, slope, simplify=F)
radj <- sapply(fit.l,function(i)summary(i)$adj.r.squared)
#print(radj)
brk.l <- sapply(fit.l ,function(i)i$psi[,2], simplify=F)
id.l <- sapply(fit.l, function(i)i$id.group, simplify=F)

if(length(step.r)>1){
radj.diff <- diff(radj)
radj.whichmax <- which(radj.diff>cutdiff)
radj.max <- max(radj)
if(length(radj.whichmax)>0)r.choose <- max(radj.whichmax)+1
if(length(radj.whichmax)==0 & radj[1]>lm.radj) r.choose <- 1 

if(length(radj.whichmax)==0& radj[1] <= lm.radj){
# if none of them satisfy, then take the linear
  out <- list(id.sign=lm.id.sign, slp=lm.slp, slp.sign=lm.sign, slp.pval=lm.pval,
			    bp=NA, fitted=lm.fit,radj=lm.radj,fit=lm1)
	if(keepfit==FALSE)out <- out[1:7]
	return(out)
}
	
while((min(table(id.l[[r.choose]]))<min.num.in.seg) & r.choose>1) r.choose <- r.choose - 1

if(r.choose==1 & (min(table(id.l[[r.choose]]))<min.num.in.seg)){
		# if 1 bp gives small segment, then take the linear
	   out <- list(id.sign=lm.id.sign, slp=lm.slp, slp.sign=lm.sign, slp.pval=lm.pval,
					        bp=NA, fitted=lm.fit,radj=lm.radj,fit=lm1)
		   if(keepfit==FALSE)out <- out[1:7]
		   return(out)
					}
}


if(length(step.r)==1) {
	r.choose <- 1
	radj.max <- radj
}

if(radj.max < lm.radj){
	out <- list(id.sign=lm.id.sign, slp=lm.slp, slp.sign=lm.sign, slp.pval=lm.pval, 
		bp=NA, fitted=lm.fit,radj=lm.radj,fit=lm1)
	if(keepfit==FALSE)out <- out[1:7]
	return(out) 
	# if lm is better 
	break
}

r.choose.ori <- step.r[r.choose] # actual k (before remove the NA fitting)
#message(r.choose.ori)

fit.choose <- fit.l[[r.choose]]
fv.choose <- fitted.values(fit.choose)
bp.choose <- brk.l[[r.choose]]
slp.choose <- slp.l[[r.choose]][[1]][,1]
slp.t <- slp.l[[r.choose]][[1]][,3]
slp.pval <- pt(-abs(slp.t),1)
slp.sign <- ifelse(slp.t>0,1,-1)
slp.sign[which(slp.pval>pvalcut)] <- 0
id.choose <- id.l[[r.choose]]
id.sign <- slp.sign[id.choose+1]
names(id.sign) <- colnames(data)
out = list(id.sign=id.sign, slp=slp.choose, slp.sign=slp.sign, slp.pval=slp.pval, bp=bp.choose, fitted=fv.choose,radj=radj[r.choose],fit=fit.choose)
if(keepfit==FALSE)out <- out[1:7]
out
}




