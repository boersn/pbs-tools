#===============================================================================
# Module 2: Biology
# -----------------
#  calcLenWt.......Calculate length-weight relationship for a fish.
#  calcSG..........Calculate growth curve using Schnute growth model.
#  calcVB..........Calculate von Bertalanffy growth curve.
#  compCsum........Compare cumulative sum curves.
#  estOgive........Creates ogives of some metric (e.g., % maturity at age).
#  genPa           Generate proportions-at-age using catch curve composition.
#  histMetric......Create a matrix of histograms for a specified metric.
#  histTail........Create a histogram showing tail details.
#  mapMaturity.....Plot maturity chart of stages by month.
#  plotProp........Plot proportion-at-age from GFBio specimen data.
#  predictRER......Predict Rougheye Rockfish from biological data.
#  processBio......Process results from 'gfb_bio.sql' query.
#  reportCatchAge..Report analyses from catch-at-age report.
#  requestAges.....Determine which otoliths to sample for ageing requests.
#  simBSR..........Simulate Blackspotted Rockfish biological data.
#  simRER..........Simulate Rougheye Rockfish biological data.
#  sumBioTabs......Summarize frequency occurrence of biological samples.
#  weightBio.......Weight age/length frequencies/proportions by catch.
#===============================================================================

#calcLenWt------------------------------2011-06-15
# Calculate length-weight relationship for a fish.
#-----------------------------------------------RH
calcLenWt <- function(dat=bio440, strSpp="440", areas=NULL, 
    ttype=NULL, stype=NULL, plotit=FALSE) {

	# Setup the jpeg device for import to word, half page with 2 plots side by side
	createJPG <- function(plotName,rc=c(2,2)) {
		plotName <- paste(plotName,"jpg",sep=".")
		jpeg(plotName, quality=100, res=300, width=1800, height=900)
		par(mfrow=rc,cex=1.5)
		par(mar=c(4,4,1,1),oma=c(1,1,1,1)) }

	# Setup the png device for import to word, half page with 2 plots side by side
	createPNG <- function(plotName,rc=c(2,2)) {
		plotName <- paste(plotName,"png",sep=".")
		#png(plotName, units="in", res=300, width=6.5, height=7)
		png(plotName, units="in", res=300, width=6.5, height=7)
		par(mfrow=rc,cex=1.0,mar=c(3.5,3,1.5,.1),oma=c(0,0,0,0),mgp=c(2,.5,0)) }

	# Setup the png device for import to word, half page with 2 plots side by side
	createWMF <- function(plotName,rc=c(1,2)) {
		plotName <- paste(plotName,"wmf",sep=".")
		win.metafile(plotName, width=9, height=5)
		par(mfrow=rc,cex=1.5)
		par(mar=c(4,4,1,1),oma=c(1,1,1,1)) }

	dat <- dat[!is.na(dat$wt) & !is.na(dat$len) & !is.na(dat$sex),]
	dat$len <- dat$len/10 # change from mm to cm
	dat$wt  <- dat$wt/1000 # change from g to kg
	dat <- dat[is.element(dat$major,1:9),]
	if (!is.null(ttype)) dat <- dat[is.element(dat$ttype,unique(unlist(ttype))),]
	if (!is.null(stype)) dat <- dat[is.element(dat$stype,stype),]
	if (is.null(areas)) { areas <- c("Coast"); dat$area <- rep(areas,nrow(dat)) }
	else {dat$area <- dat$major; dat <- dat[is.element(dat$area,unique(unlist(areas))),] }
	ylim <- range(dat$wt,na.rm=TRUE)
	xlim <- range(dat$len,na.rm=TRUE)
	sex <- list(1,2,1:2,c(0,3),0:3); names(sex) <- c("Males","Females","M+F","Unknown","All")
	out <- array(NA,dim=c(length(sex),9,length(ttype),length(areas)),
		dimnames=list(names(sex),c("n","a","SEa","b","SEb","w","SDw","wmin","wmax"),
		sapply(ttype,function(x){paste(paste(x,collapse="|",sep=""),sep="")}),
		sapply(areas,function(x){paste(paste(x,collapse="|",sep=""),sep="")}) ))
	names(dimnames(out)) <- c("sex","par","ttype","area")
	#out <- list(dat=dat)
	for (ar in areas) {
		adat <- dat[is.element(dat$area,ar),]
		if (nrow(adat)==0) next
		arName <- paste(paste(ar,collapse="|",sep=""),sep="")
		for (tt in ttype) {
			tdat <- adat[is.element(adat$ttype,tt),]
			if (nrow(tdat)==0) next
			ttName <- paste(paste(tt,collapse="|",sep=""),sep="")
			plotName <- gsub("\\|","",paste("LenWt",strSpp,arName,ttName,sep="-"))
			if (plotit) createPNG(plotName)
			else par(mfrow=c(2,2),cex=2.0,mar=c(3.5,3,1.5,.1),oma=c(0,0,0,0),mgp=c(2,.5,0),cex=1)
			for (i in 1:length(sex)) {
				ii   <- sex[[i]]; iii <- names(sex)[i]
				idat <- tdat[is.element(tdat$sex,ii),];
				n    <- nrow(idat); #out[[iii]] <- idat
				if (n==0) {
					if (iii=="Unknown") next else
					{plot(0,0,type="n",axes=F,xlab="",ylab=""); addLabel(.5,.5,"NO DATA"); next }}
				if (n>1) {
					fit1 <- lm(log(wt)~log(len), data=idat)
					a <- fit1$coef[1]; aa <- format(signif(a,4),scientific=FALSE)
					b <- fit1$coef[2];      bb <- format(signif(b,4),big.mark=",",scientific=FALSE)
					se <- summary(fit1)$coefficients[,"Std. Error"]
					Wt <- (exp(a) * (0:xlim[2])^b) }
				else {a=NA;b=NA}
				w=idat$wt
				ovec <- c(n=n,a=as.vector(a),SEa=as.vector(se[1]),b=as.vector(b),SEb=as.vector(se[2]),
					w=mean(w),SDw=sd(w),wmin=min(w),wmax=max(w))
				out[iii,,ttName,arName] <- ovec

				if (iii!="Unknown") {
					plot(jitter(idat$len,0), jitter(idat$wt,0), pch=15, col="orangered", cex=0.5,
					xlab="     Length (cm)", ylab="   Weight (kg)", main=iii, 
					xlim=xlim, ylim=ylim, bty="l")
					if (n>1) lines(0:xlim[2], Wt, col="blue", lwd=3)

					mw <- format(round(mean(idat$wt,na.rm=T),2),big.mark=",")
					addLabel(0.1,0.9,bquote(bolditalic(bar(W)) == .(mw)),adj=0,cex=0.8)
					addLabel(0.1,0.85,bquote(bolditalic(n)==.(format(n,big.mark=","))),adj=0,cex=0.8)
					addLabel(0.1,0.80,bquote(bolditalic(a)==.(aa)),adj=0,cex=0.8)
					addLabel(0.1,0.75,bquote(bolditalic(b)==.(bb)),adj=0,cex=0.8)
					addLabel(.9,.1,paste(arName," - trip type (",ttName,")",sep=""),adj=1,cex=.7)

					box(bty="l") } }
			if (plotit) dev.off()
	} } 
	eval(parse(text="out <<- out; dat <<- dat"))
	
# Output table for Pre-COSEWIC
	fn <- paste("LenWt-","440",".csv",sep="")
	tkey <- c("Non Obs Comm","Research","Charter","Obs Comm","Res + Chart","Commercial")
	names(tkey) <- c("1","2","3","4","2|3","1|4")
	ukey <- dimnames(out)$ttype
	header <- dimnames(out)$par;  header=gsub("a$","log(a)",dimnames(out)$par)
	cat(paste(c("",header),collapse=","),"\n",file=fn)
	for (i in c("Males","Females","M+F")) {
		iout <- t(out[i,,,]); dimnames(iout)[[1]] <- tkey[ukey]
		cat(i,"\n",file=fn,append=T)
		write.table(iout,file=fn,col.names=F,append=T,sep=",") }
	invisible(out) }
#----------------------------------------calcLenWt

#calcSG---------------------------------2010-08-09
# Calculate growth curve using Schnute growth model.
# Note: ameth=3 otoliths broken & burnt
#-----------------------------------------------RH
calcSG <- function(dat=pop.age, strSpp="", yfld="len", tau=c(5,40), 
     areas=list(major=NULL, minor=NULL, locality=NULL, srfa=NULL,
     srfs=NULL, popa=NULL), ttype=list(c(1,4),c(2,3)), stype=NULL,
     year=NULL, ameth=3, allTT=TRUE, jit=c(0,0), 
     pix=FALSE, wmf=FALSE, singles=FALSE, pages=FALSE) {

	assign("PBSfish",list(module="M02_Biology",func="calcSG"),envir=.GlobalEnv)
	#Subfunctions----------------------------------
	SGfun <- function(P) {
		aModel  <- function(P,xobs,tau=NULL,is.pred=FALSE) {
			# Growth models - Schnute 1981
			a<-P[1]; b<-P[2]; y1<-P[3]; y2<-P[4];
			aa <- round(a,10); bb <- round(b,10); # For testing zero-values
			t1 <- tau[1]; t2 <- tau[2];
			#---Case 1---
			if (aa!=0 & bb!=0) {
				frac <- (1 - exp(-a*(xobs-t1))) / (1 - exp(-a*(t2-t1)));
				y0 <- y1^b + (y2^b - y1^b) * frac; y0 <- GT0(y0,eps=1e-8);
				y <- y0^(1/b); return(y);  }
			#---Case 2---
			if (aa!=0 & bb==0) {
				frac <- (1 - exp(-a*(xobs-t1))) / (1 - exp(-a*(t2-t1)));
				y <- y1 * exp(log(y2/y1) * frac); return(y);  }
			#---Case 3---
			if (aa==0 & bb!=0) {
				frac <- (xobs-t1) / (t2-t1);  y0 <- y1^b + (y2^b - y1^b) * frac;
				y0 <- GT0(y0,eps=1e-8); y <- y0^(1/b); return(y);  }
			#---Case 4---
			if (aa==0 & bb==0) {
				frac <- (xobs-t1) / (t2-t1);
				y <- y1 * exp(log(y2/y1) * frac); return(y);  }
		}
		unpackList(SG,scope="L") # contains tau & is.pred
		if (is.pred) xobs=xpred else xobs=SGdat$age
		ypred = aModel(P=P,xobs=xobs,tau=tau,is.pred=is.pred)
		if (is.pred)  return(ypred) #{ SG$yobs <<- ypred; return(ypred); }
		yobs  = SGdat$yval
		n <- length(yobs);  ssq <- sum( (yobs-ypred)^2 )
		return(n*log(ssq)) }

	calcP <- function(P,Pfix) { # t0, yinf, tstar, ystar, zstar (Eqns 24-28, Schnute 1981)
		a<-P[1]; b<-P[2]; y1<-P[3]; y2<-P[4]; t1 <- Pfix[1]; t2 <- Pfix[2];
		aa <- round(a,10); bb <- round(b,10);
		t0 <- NA; yinf <- NA; tstar <- NA; ystar <- NA;
		if (aa!=0 & bb!=0) {
			t0 <- t1 + t2 - (1/a)*log((exp(a*t2)*y2^b - exp(a*t1)*y1^b)/(y2^b - y1^b));
			yinf <- ((exp(a*t2)*y2^b - exp(a*t1)*y1^b)/(exp(a*t2)-exp(a*t1)))^(1/b);
			tstar <- t1 + t2 - (1/a)*log(b*(exp(a*t2)*y2^b - exp(a*t1)*y1^b)/(y2^b - y1^b));
			ystar <- ((1-b)*(exp(a*t2)*y2^b - exp(a*t1)*y1^b)/(exp(a*t2)-exp(a*t1)))^(1/b); };
		if (aa==0 & bb!=0) {
			t0 <- t1 + t2 - (t2*y2^b - t1*y1^b)/(y2^b - y1^b); };
		if (aa!=0 & bb==0) {
			yinf <- exp((exp(a*t2)*log(y2) - exp(a*t1)*log(y1))/(exp(a*t2)-exp(a*t1)));
			tstar <- t1 + t2 - (1/a)*log((exp(a*t2) - exp(a*t1))/log(y2/y1));
			ystar <- exp((exp(a*t2)*log(y2) - exp(a*t1)*log(y1))/(exp(a*t2)-exp(a*t1)) - 1); }
		zstar <- a / (1-b);
		return(list(t0=as.vector(t0),yinf=as.vector(yinf),tstar=as.vector(tstar),
			ystar=as.vector(ystar),zstar=as.vector(zstar))) }

	createPNG <- function(plotName,rc=c(1,3)) {
		plotName <- paste(plotName,"png",sep=".")
		png(plotName, units="in", res=300, width=6.5, height=3*rc[1])
		expandGraph(mfrow=rc,mar=c(2.75,2.5,1.5,.1),oma=c(0,0,0,0),mgp=c(1.5,.5,0),cex=0.8) }
	createWMF <- function(plotName,rc=c(1,3)) {
		plotName <- paste(plotName,"wmf",sep=".")
		win.metafile(plotName, width=6.5, height=3*rc[1])
		expandGraph(mfrow=rc,mar=c(2.75,2.5,1.5,.1),oma=c(0,0,0,0),mgp=c(1.5,.5,0),cex=0.8) }
	#----------------------------------Subfunctions

	unpackList(areas,scope="L")
	fnam=as.character(substitute(dat))
	expr=paste("getFile(",fnam,",scope=\"G\"); dat=",fnam,sep="")
	eval(parse(text=expr))
	
	FLDS=names(dat)
	if (!is.element(yfld,FLDS)) showError(yfld,"nofields")
	dat$yval = dat[,yfld] # can be 'len' or 'wt'
	isLen=isWt=FALSE
	if (is.element(yfld,c("len","length"))) {names(yfld)="length"; isLen=TRUE}
	if (is.element(yfld,c("wt","weight")))  {names(yfld)="weight"; isWt =TRUE}

	attSpp=attributes(dat)$spp
	if (is.null(strSpp) || strSpp=="") {
		if (is.null(attributes(dat)$spp) || attributes(dat)$spp=="") strSpp="999"
		else strSpp=attSpp }
	else if (!is.null(attSpp) && attSpp!=strSpp)
		showError(paste("Specified strSpp '",strSpp,"' differs from species attribute '",attSpp,"' of data file",sep=""))
	if (any(is.element(c("spp","species","sppcode"),FLDS))) {
		fldSpp=intersect(c("spp","species","sppcode"),FLDS)[1]
		dat=dat[is.element(dat[,fldSpp],strSpp),] }

	dat <- dat[!is.na(dat$age) & !is.na(dat$yval) & !is.na(dat$sex),]
	# Qualify data
	z=rep(TRUE,nrow(dat))
	if (isLen) {
		if (strSpp=="394" || strSpp=="RER") z=dat$yval>100
		if (strSpp=="396" || strSpp=="POP") z=dat$yval>75 & dat$yval<600
		if (strSpp=="440" || strSpp=="YMR") {
			z1=dat$yval>=210 & dat$yval<=600; z2=dat$age<=90; z=z1&z2 }
		dat$yval <- dat$yval/10. }  # change from mm to cm
	if (isWt) {
		if (strSpp=="396" || strSpp=="POP") z=dat$yval<2000
		dat$yval = dat$yval/1000. } # change from g to kg
	if (!all(z==TRUE)) dat=dat[z,] # keep good, remove outliers

	aflds=c("major","minor","locality","srfa","srfs","popa")
	yarea=character(0)
	flds=c("ttype","stype","ameth","year")#,names(areas))
	for (i in flds) {
		expr=paste("dat=biteData(dat,",i,")",sep=""); eval(parse(text=expr))
		if (any(i==aflds)) eval(parse(text=paste("yarea=union(yarea,",i,")"))) }
	if (nrow(dat)==0) {
		if (pix|wmf) return()
		else showError("No records selected for specified qualification") }

	if (!allTT) ttype=sort(unique(dat$ttype))
	tlab=sapply(ttype,function(x){paste(paste(x,collapse="",sep=""),sep="")},simplify=TRUE); ntt=length(tlab)
	alist=sapply(areas,function(x){sapply(x,function(x){paste(x,collapse="")},simplify=FALSE)},simplify=FALSE)
	alen=sapply(alist,length)
	if (all(alen==0)) {
		areas=list(area="NA"); alen=1; names(alen)="area"; alab="areaNA"
		dat$area=rep("NA",nrow(dat)) }
	else 
		alab=paste(rep(names(alist),each=alen),unlist(alist),sep="")
	nar=length(alab)

	xlim <- c(0,max(dat$age,na.rm=TRUE))
	ylim <- c(0,max(dat$yval,na.rm=TRUE))
	sex <- list(1,2,1:2,c(0,3),0:3); names(sex) <- c("Males","Females","M+F","Unknown","All")
	out <- array(NA,dim=c(length(sex),13,ntt,nar),
		dimnames=list(names(sex),c("n","a","b","y1","y2","t0","yinf","tstar","ystar","zstar","Ymod","Ymin","Ymax"),tlab,alab ))
	names(dimnames(out)) <- c("sex","par","ttype","area")

	getFile("parVec", use.pkg=TRUE)
	pVec <- parVec[["SGM"]][[names(yfld)]][[strSpp]]
	if (is.null(pVec)) pVec=parVec[["SGM"]][[names(yfld)]][["POP"]] # default

	# Labels & names --------------------
	aName=paste("-areas(",paste(alab,collapse="+"),")",sep="")      # area label
	tName=paste("-tt(",paste(tlab,collapse="+"),")",sep="")         # trip type label
	pName=paste(ifelse(isLen,"Len","Wt"),"Age-",sep="")             # property label
	yName=ifelse(is.null(year),"",paste("-(",paste(unique(range(year)),collapse="-"),")",sep=""))  # year label
	fName=paste("fits",gsub("[()]","",gsub("-","_",yName)),sep="")  # fits label
	plotName = paste(pName,strSpp,aName,tName,yName,"-SG",sep="")
	csv=paste("fits-",plotName,".csv",sep="")
	adm=paste("fits-",plotName,".dat",sep="")
	#------------------------------------
	
	if (!pix&!wmf) { resetGraph()
		expandGraph(mfrow=c(length(ttype),3),mar=c(2.75,2.5,1.5,.1),oma=c(0,0,0,0),mgp=c(1.5,.5,0),cex=0.8) }
	else if ((!singles&!pages) && (pix|wmf)) {
		if (pix)      createPNG(plotName,rc=c(length(alab)*length(tlab),3))
		else if (wmf) createWMF(plotName,rc=c(length(alab)*length(tlab),3)) }

	fits=list()
	if (!is.null(year)) yrlim = range(year)
	else if (is.element("year",names(dat))) yrlim = range(dat$year,na.rm=TRUE)
	else if (is.element("date",names(dat))) yrlim = range(is.numeric(substring(dat$date,1,4)),na.rm=TRUE)
	else yrlim = rep(as.numeric(substring(Sys.time(),1,4)),2)
	cat(paste("Fits for",plotName),"\n",file=csv)
	mess=c("# Parameters for ",plotName,"\n\n# number of years\n",diff(yrlim)+1,
	       "\n# first year of period when vonB parameters are valid\n",yrlim[1],
	       "\n# last year for parameters\n",yrlim[2],"\n\n")
	cat(paste(mess,collapse=""),file=adm)

	for (a in names(areas)) {
		for (aa in 1:alen[a]) {
			aaa=areas[[a]][[aa]]; assign(a,aaa)
			expr=paste("adat=biteData(dat,",a,")",sep=""); eval(parse(text=expr))
			amat=paste(a,"",paste(aaa,collapse=""),sep="")
			aaName <- paste(pName,strSpp,"-area(",amat,")",tName,"-SG",sep="")
			if (pages && pix)      createPNG(aaName,rc=c(length(tlab),3))
			else if (pages && wmf) createWMF(aaName,rc=c(length(tlab),3))
			for (tt in ttype) {
				tmat=paste(tt,collapse="")
				tdat <- adat[is.element(adat$ttype,tt),]
				if (nrow(tdat)==0) next
				ttName <- paste(pName,strSpp,aName,paste("-tt(",tmat,")",sep=""),"-SG",sep="")
				if (singles && pix) createPNG(ttName)
				else if (singles && wmf) createWMF(ttName)
				for (i in 1:length(sex)) {
					ii   <- sex[[i]]; iii <- names(sex)[i]
					idat <- tdat[is.element(tdat$sex,ii),];
					n    <- nrow(idat); #out[[iii]] <- idat
					if (n==0) {
						out[iii,"n",tmat,amat] = 0
						if (any(iii==c("All","Unknown"))) next 
						else {
							plot(0,0,type="n",axes=FALSE,xlab="",ylab="")
							addLabel(.5,.5,"NO DATA"); next }}
					if (n==1) {
						out[iii,c("n","Ymod","Ymin","Ymax"),tmat,amat] = c(1,rep(idat$yval,3))
						if (any(iii==c("All","Unknown"))) next 
						else {
							points(idat$age,idat$yval,pch=21,bg="orangered",cex=0.8); next }}
					if (n>1) {
						yval <- idat$yval; age <- idat$age
						assign("SGdat",idat,envir=.GlobalEnv)
						xy <- hist(idat$yval,nclass=20,plot=FALSE);
						Ymod <- xy$breaks[2:length(xy$breaks)][is.element(xy$density,max(xy$density))]
						Ymod <- mean(Ymod)
						Ymin <- min(idat$yval,na.rm=TRUE); Ymax <- max(idat$yval,na.rm=TRUE)
						assign("SG",list(tau=tau,is.pred=FALSE,xpred=NULL),envir=.GlobalEnv)
						calcMin(pvec=pVec,func=SGfun);
						fmin <- PBSmin$fmin; np <- sum(pVec[,4]); ng <- nrow(SGdat);
						AICc <- 2*fmin + 2*np * (ng/(ng-np-1)); packList("AICc","PBSmin");  #print(PBSmin)
						P <- PBSmin$end
						Pcalc <- calcP(P,tau); # t0, yinf, tstar, ystar, zstar (Eqns 24-28, Schnute 1981)
						unpackList(Pcalc)
						a  = P[1]; par1 = format(signif(a,4),big.mark=",",scientific=FALSE)
						b  = P[2]; par2 = format(signif(b,4),big.mark=",",scientific=FALSE)
						y1 = P[3]; par3 = format(signif(y1,3),big.mark=",",scientific=FALSE)
						y2 = P[4]; par4 = format(signif(y2,3),big.mark=",",scientific=FALSE)
						par5 = format(signif(t0,3),big.mark=",",scientific=FALSE)
						par6 = format(signif(yinf,3),big.mark=",",scientific=FALSE)
						ovec <- c(n=n,a,b,y1,y2,t0=t0,yinf=yinf,tstar=tstar,ystar=ystar,zstar=zstar,Ymod=Ymod,Ymin=Ymin,Ymax=Ymax)
						out[iii,,tmat,amat] <- ovec

						# Plot jittered data and add SGfun fit line
						if (any(iii==c("Males","Females","M+F"))) {
							subtit = paste(amat,", ttype (",tmat,")",sep="")
							plot(0,0,type="n", xlab="     Age",ylab=ifelse(isLen,"   Length (cm)","   Weight (kg)"),
								main=iii, xlim=xlim, ylim=ylim, bty="l")
							abline(h=seq(0,ylim[2],5),v=seq(0,xlim[2],ifelse(xlim[2]<=50,5,10)),col="grey90")
							points(jitter(age,jit[1]),jitter(yval,jit[2]),pch=149,col="orangered",cex=0.7)
							xpred <- 0:xlim[2]
							assign("SG",list(tau=tau,is.pred=TRUE,xpred=xpred),envir=.GlobalEnv)
							ypred <- SGfun(P)
						#print(amat);print(tmat);print(iii)
							fits[[amat]][[tmat]][[iii]] = list(xpred=xpred,ypred=ypred)
							lines(xpred,ypred,col="blue", lwd=2)
							mw <- format(round(mean(idat$wt,na.rm=TRUE),1),nsmall=1)
							posX=0.6; posY=.37; difY=.05; cexlab=ifelse(pix|wmf,0.7,0.8)
							addLabel(posX,posY-difY*0,bquote(bolditalic(n)==.(format(n,big.mark=","))),adj=0,cex=cexlab)
							addLabel(posX,posY-difY*1,bquote(bolditalic(a) == .(par1)),adj=0,cex=cexlab)
							addLabel(posX,posY-difY*2,bquote(bolditalic(b)==.(par2)),adj=0,cex=cexlab)
							addLabel(posX,posY-difY*3,bquote(bolditalic(y)[1]==.(par3)),adj=0,cex=cexlab)
							addLabel(posX,posY-difY*4,bquote(bolditalic(y)[2]==.(par4)),adj=0,cex=cexlab)
							addLabel(posX,posY-difY*5,bquote(bolditalic(t)[0]==.(par5)),adj=0,cex=cexlab)
							addLabel(posX,posY-difY*6,bquote(bolditalic(y)[infinity]==.(par6)),adj=0,cex=cexlab)
							if (iii=="Females") addLabel(.5,.96,subtit,adj=c(.5,0),cex=cexlab+0.1)
							box(bty="l")
						}
					}
				}	
				if (singles && (pix|wmf)) dev.off()
				cat(paste("\nArea: ",amat,"   Trip type: ",tmat,sep=""),"\n",file=csv,append=TRUE)
				cat("age,females,males,M+F","\n",file=csv,append=TRUE)
				mf=cbind(sapply(fits[[amat]][[tmat]][["Females"]],function(x){x},simplify=TRUE),
					sapply(fits[[amat]][[tmat]][["Males"]],function(x){x},simplify=TRUE)[,2],
					sapply(fits[[amat]][[tmat]][["M+F"]],function(x){x},simplify=TRUE)[,2])
				write.table(mf,file=csv,append=TRUE,sep=",",row.names=FALSE,col.names=FALSE)
				cat(paste("# Area: ",amat,"   Trip type: ",tmat,sep=""),"\n",file=adm,append=TRUE)
				mess=c("# pars: n  a  b  y1  y2  t0  yinf\n")
				cat(paste(mess,collapse=""),file=adm,append=TRUE)
				mess = cbind(n=out[c("Males","Females"),"n",tmat,amat],
					apply(out[c("Males","Females"),2:7,tmat,amat],1,function(x){
					paste(show0(format(round(x,6),scientific=FALSE,width=12,justify="right"),6,add2int=TRUE),collapse="") } ) )
				cat(paste(apply(mess,1,paste,collapse=""),collapse="\n"),sep="",file=adm,append=TRUE)
				cat("\n\n",file=adm,append=TRUE) 
			}
			if (pages && (pix|wmf)) dev.off()
	}	}
	if ((!singles&!pages) && (pix|wmf)) dev.off()
	assign(fName,fits,envir=.GlobalEnv)
	stuff=c("out","pVec","xlim","ylim","alab","tlab","aName","tName","aaName","ttName","strSpp","fits")
	packList(stuff,"PBSfish")
	invisible() }
#-------------------------------------------calcSG

#calcVB---------------------------------2010-08-09
# Calculate von Bertalanffy growth curve.
# Note: ameth=3 otoliths broken & burnt
#-----------------------------------------------RH
calcVB <- function(dat=pop.age, strSpp="", yfld="len", fixt0=FALSE, 
     areas=list(major=NULL, minor=NULL, locality=NULL, srfa=NULL,
     srfs=NULL, popa=NULL), ttype=list(c(1,4),c(2,3)), stype=NULL,
     year=NULL, ameth=3, allTT=TRUE, jit=c(0,0), 
     pix=FALSE, wmf=FALSE, singles=FALSE, pages=FALSE) {

	assign("PBSfish",list(module="M02_Biology",func="calcVB"),envir=.GlobalEnv)
	#Subfunctions----------------------------------
	VBfun <- function(P) {
		Yinf <- P[1]; K <- P[2]; t0 <- P[3];
		obs  <- VBdat$yval;
		pred <- Yinf * (1 - exp(-K*(VBdat$age-t0)) );
		n    <- length(obs);
		ssq  <- sum( (obs-pred)^2 );
		return(n*log(ssq)); };
	createPNG <- function(plotName,rc=c(1,3)) {
		plotName <- paste(plotName,"png",sep=".")
		png(plotName, units="in", res=300, width=6.5, height=3*rc[1])
		expandGraph(mfrow=rc,mar=c(2.75,2.5,1.5,.1),oma=c(0,0,0,0),mgp=c(1.5,.5,0),cex=0.8) }
	createWMF <- function(plotName,rc=c(1,3)) {
		plotName <- paste(plotName,"wmf",sep=".")
		win.metafile(plotName, width=6.5, height=3*rc[1])
		expandGraph(mfrow=rc,mar=c(2.75,2.5,1.5,.1),oma=c(0,0,0,0),mgp=c(1.5,.5,0),cex=0.8) }
	#----------------------------------Subfunctions

	unpackList(areas,scope="L")
	fnam=as.character(substitute(dat))
	expr=paste("getFile(",fnam,",scope=\"G\"); dat=",fnam,sep="")
	eval(parse(text=expr))
	
	FLDS=names(dat)
	if (!is.element(yfld,FLDS)) showError(yfld,"nofields")
	dat$yval = dat[,yfld] # can be 'len' or 'wt'
	isLen=isWt=FALSE
	if (is.element(yfld,c("len","length"))) {names(yfld)="length"; isLen=TRUE}
	if (is.element(yfld,c("wt","weight")))  {names(yfld)="weight"; isWt =TRUE}

	attSpp=attributes(dat)$spp
	if (is.null(strSpp) || strSpp=="") {
		if (is.null(attributes(dat)$spp) || attributes(dat)$spp=="") strSpp="999"
		else strSpp=attSpp }
	else if (!is.null(attSpp) && attSpp!=strSpp)
		showError(paste("Specified strSpp '",strSpp,"' differs from species attribute '",attSpp,"' of data file",sep=""))
	if (any(is.element(c("spp","species","sppcode"),FLDS))) {
		fldSpp=intersect(c("spp","species","sppcode"),FLDS)[1]
		dat=dat[is.element(dat[,fldSpp],strSpp),] }

	dat <- dat[!is.na(dat$age) & !is.na(dat$yval) & !is.na(dat$sex),]
	# Qualify data
	z=rep(TRUE,nrow(dat))
	if (isLen) {
		if (strSpp=="394" || strSpp=="RER") z=dat$yval>100
		if (strSpp=="396" || strSpp=="POP") z=dat$yval>75 & dat$yval<600
		if (strSpp=="440" || strSpp=="YMR") {
			z1=dat$yval>=210 & dat$yval<=600; z2=dat$age<=90; z=z1&z2 }
		dat$yval <- dat$yval/10. }  # change from mm to cm
	if (isWt) {
		if (strSpp=="396" || strSpp=="POP") z=dat$yval<2000
		dat$yval = dat$yval/1000. } # change from g to kg
	if (!all(z==TRUE)) dat=dat[z,] # keep good, remove outliers

	aflds=c("major","minor","locality","srfa","srfs","popa")
	yarea=character(0)
	flds=c("ttype","stype","ameth","year")#,names(areas))
	for (i in flds) {
		expr=paste("dat=biteData(dat,",i,")",sep=""); eval(parse(text=expr))
		if (any(i==aflds)) eval(parse(text=paste("yarea=union(yarea,",i,")"))) }
	if (nrow(dat)==0) {
		if (pix|wmf) return()
		else showError("No records selected for specified qualification") }

	if (!allTT) ttype=sort(unique(dat$ttype))
	tlab=sapply(ttype,function(x){paste(paste(x,collapse="",sep=""),sep="")},simplify=TRUE); ntt=length(tlab)
	alist=sapply(areas,function(x){sapply(x,function(x){paste(x,collapse="")},simplify=FALSE)},simplify=FALSE)
	alen=sapply(alist,length)
	if (all(alen==0)) {
		areas=list(area="NA"); alen=1; names(alen)="area"; alab="areaNA"
		dat$area=rep("NA",nrow(dat)) }
	else 
		alab=paste(rep(names(alist),each=alen),unlist(alist),sep="")
	nar=length(alab)

	xlim <- c(0,max(dat$age,na.rm=TRUE))
	ylim <- c(0,max(dat$yval,na.rm=TRUE))
	sex <- list(1,2,1:2,c(0,3),0:3); names(sex) <- c("Males","Females","M+F","Unknown","All")
	out <- array(NA,dim=c(length(sex),7,ntt,nar),
		dimnames=list(names(sex),c("n","Yinf","K","t0","Ymod","Ymin","Ymax"),tlab,alab ))
	names(dimnames(out)) <- c("sex","par","ttype","area")

	getFile("parVec",use.pkg=TRUE)
	pVec <- parVec[["vonB"]][[names(yfld)]][[strSpp]]
	if (is.null(pVec)) pVec=parVec[["vonB"]][[names(yfld)]][["POP"]] # default

	# Labels & names --------------------
	aName=paste("-areas(",paste(alab,collapse="+"),")",sep="")      # area label
	tName=paste("-tt(",paste(tlab,collapse="+"),")",sep="")         # trip type label
	pName=paste(ifelse(isLen,"Len","Wt"),"Age-",sep="")             # property label
	yName=ifelse(is.null(year),"",paste("-(",paste(unique(range(year)),collapse="-"),")",sep=""))  # year label
	fName=paste("fits",gsub("[()]","",gsub("-","_",yName)),sep="")  # fits label
	plotName = paste(pName,strSpp,aName,tName,yName,"-VB",sep="")
	csv=paste("fits-",plotName,".csv",sep="")
	adm=paste("fits-",plotName,".dat",sep="")
	#------------------------------------
	
	if (!pix&!wmf) { resetGraph()
		expandGraph(mfrow=c(length(ttype),3),mar=c(2.75,2.5,1.5,.1),oma=c(0,0,0,0),mgp=c(1.5,.5,0),cex=0.8) }
	else if ((!singles&!pages) && (pix|wmf)) {
		if (pix)      createPNG(plotName,rc=c(length(alab)*length(tlab),3))
		else if (wmf) createWMF(plotName,rc=c(length(alab)*length(tlab),3)) }

	fits=list()
	if (!is.null(year)) yrlim = range(year)
	else if (is.element("year",names(dat))) yrlim = range(dat$year,na.rm=TRUE)
	else if (is.element("date",names(dat))) yrlim = range(is.numeric(substring(dat$date,1,4)),na.rm=TRUE)
	else yrlim = rep(as.numeric(substring(Sys.time(),1,4)),2)
	cat(paste("Fits for",plotName),"\n",file=csv)
	mess=c("# Parameters for ",plotName,"\n\n# number of years\n",diff(yrlim)+1,
	       "\n# first year of period when vonB parameters are valid\n",yrlim[1],
	       "\n# last year for parameters\n",yrlim[2],"\n\n")
	cat(paste(mess,collapse=""),file=adm)

	for (a in names(areas)) {
		for (aa in 1:alen[a]) {
			aaa=areas[[a]][[aa]]; assign(a,aaa)
			expr=paste("adat=biteData(dat,",a,")",sep=""); eval(parse(text=expr))
			amat=paste(a,"",paste(aaa,collapse=""),sep="")
			aaName <- paste(pName,strSpp,"-area(",amat,")",tName,"-VB",sep="")
			if (pages && pix)      createPNG(aaName,rc=c(length(tlab),3))
			else if (pages && wmf) createWMF(aaName,rc=c(length(tlab),3))
			for (tt in ttype) {
				tmat=paste(tt,collapse="")
				tdat <- adat[is.element(adat$ttype,tt),]
				if (nrow(tdat)==0) next
				ttName <- paste(pName,strSpp,aName,paste("-tt(",tmat,")",sep=""),"-VB",sep="")
				if (singles && pix) createPNG(ttName)
				else if (singles && wmf) createWMF(ttName)
				for (i in 1:length(sex)) {
					ii   <- sex[[i]]; iii <- names(sex)[i]
					idat <- tdat[is.element(tdat$sex,ii),];
					n    <- nrow(idat); #out[[iii]] <- idat
					if (n==0) {
						out[iii,"n",tmat,amat] = 0
						if (any(iii==c("All","Unknown"))) next 
						else {
							plot(0,0,type="n",axes=FALSE,xlab="",ylab="")
							addLabel(.5,.5,"NO DATA"); next }}
					if (n==1) {
						out[iii,c("n","Ymod","Ymin","Ymax"),tmat,amat] = c(1,rep(idat$yval,3))
						if (any(iii==c("All","Unknown"))) next 
						else {
							points(idat$age,idat$yval,pch=21,bg="orangered",cex=0.8); next }}
					if (n>1) {
						yval <- idat$yval; age <- idat$age
						assign("VBdat",idat,envir=.GlobalEnv)
						xy <- hist(idat$yval,nclass=20,plot=FALSE);
						Ymod <- xy$breaks[2:length(xy$breaks)][is.element(xy$density,max(xy$density))]
						Ymod <- mean(Ymod)
						Ymin <- min(idat$yval,na.rm=TRUE); Ymax <- max(idat$yval,na.rm=TRUE);
						pVec[ifelse(isLen,"Linf","Winf"),1:3] <- c(Ymod,Ymin,1.2*Ymax)
						if (fixt0) pVec[3,4]=FALSE
						calcMin(pvec=pVec,func=VBfun);
						fmin <- PBSmin$fmin; np <- sum(pVec[,4]); ng <- nrow(VBdat);
						AICc <- 2*fmin + 2*np * (ng/(ng-np-1)); packList("AICc","PBSmin");  #print(PBSmin)
						P <- PBSmin$end
						Yinf <- P[1]; par1 <- format(round(Yinf,3),big.mark=",",scientific=FALSE)
						K    <- P[2]; par2 <- format(signif(K,4),big.mark=",",scientific=FALSE)
						t0   <- P[3]; par3 <- format(signif(t0,4),big.mark=",",scientific=FALSE)
						ovec <- c(n=n,Yinf,K,t0,Ymod=Ymod,Ymin=Ymin,Ymax=Ymax)
						out[iii,,tmat,amat] <- ovec

						# Plot jittered data and add SGfun fit line
						if (any(iii==c("Males","Females","M+F"))) {
							subtit = paste(amat,", ttype (",tmat,")",sep="")
							plot(0,0,type="n", xlab="     Age",ylab=ifelse(isLen,"   Length (cm)","   Weight (kg)"),
								main=iii, xlim=xlim, ylim=ylim, bty="l")
							abline(h=seq(0,ylim[2],5),v=seq(0,xlim[2],ifelse(xlim[2]<=50,5,10)),col="grey90")
							points(jitter(age,jit[1]),jitter(yval,jit[2]),pch=149,col="orangered",cex=0.7)
							xpred <- 0:xlim[2]; ypred <- Yinf * (1-exp(-K*(xpred-t0)))
							#print(amat);print(tmat);print(iii)
							fits[[amat]][[tmat]][[iii]] = list(xpred=xpred,ypred=ypred)
							lines(xpred,ypred,col="blue", lwd=2)
							mw <- format(round(mean(idat$wt,na.rm=TRUE),1),nsmall=1)
							posX=0.6; posY=.25; difY=.05; cexlab=ifelse(pix|wmf,0.7,0.8)
							addLabel(posX,posY-difY*0,bquote(bolditalic(n)==.(format(n,big.mark=","))),adj=0,cex=cexlab)
							addLabel(posX,posY-difY*1,bquote(bolditalic(Y)[infinity] == .(par1)),adj=0,cex=cexlab)
							addLabel(posX,posY-difY*2,bquote(bolditalic(K)==.(par2)),adj=0,cex=cexlab)
							addLabel(posX,posY-difY*3,bquote(bolditalic(t)[0]==.(par3)),adj=0,cex=cexlab)
							if (iii=="Females") addLabel(.5,.96,subtit,adj=c(.5,0),cex=cexlab+0.1)
							box(bty="l")
						}
					}
				}
				if (singles && (pix|wmf)) dev.off()
				cat(paste("\nArea: ",amat,"   Trip type: ",tmat,sep=""),"\n",file=csv,append=TRUE)
				cat("age,females,males,M+F","\n",file=csv,append=TRUE)
				mf=cbind(sapply(fits[[amat]][[tmat]][["Females"]],function(x){x},simplify=TRUE),
					sapply(fits[[amat]][[tmat]][["Males"]],function(x){x},simplify=TRUE)[,2],
					sapply(fits[[amat]][[tmat]][["M+F"]],function(x){x},simplify=TRUE)[,2])
				write.table(mf,file=csv,append=TRUE,sep=",",row.names=FALSE,col.names=FALSE)
				cat(paste("# Area: ",amat,"   Trip type: ",tmat,sep=""),"\n",file=adm,append=TRUE)
				mess=c("# pars: n  Yinf  K  t0\n")
				cat(paste(mess,collapse=""),file=adm,append=TRUE)
				mess = cbind(n=out[c("Males","Females"),"n",tmat,amat],
					apply(out[c("Males","Females"),2:4,tmat,amat],1,function(x){
					paste(show0(format(round(x,6),scientific=FALSE,width=12,justify="right"),6,add2int=TRUE),collapse="") } ) )
				cat(paste(apply(mess,1,paste,collapse=""),collapse="\n"),sep="",file=adm,append=TRUE)
				cat("\n\n",file=adm,append=TRUE) 
			}
			if (pages && (pix|wmf)) dev.off()
	}	}
	if ((!singles&!pages) && (pix|wmf)) dev.off()
	assign(fName,fits,envir=.GlobalEnv)
	stuff=c("out","pVec","xlim","ylim","alab","tlab","aName","tName","aaName","ttName","strSpp","fits")
	packList(stuff,"PBSfish")
	invisible() }
#-------------------------------------------calcVB

#compCsum-------------------------------2009-11-10
# Compare cumulative sum curves
# Note: ameth=3 otoliths broken & burnt
#-----------------------------------------------RH
compCsum <- function(dat=pop.age, pro=TRUE, strSpp="", xfld="age", plus=60,
	yfac="year",areas=list(major=NULL, minor=NULL, locality=NULL, 
	srfa=NULL, srfs=NULL, popa=NULL), ttype=list(c(1,4),c(2,3)), 
	stype=c(1,2,5:8), ameth=3, allTT=TRUE, years=1998:2006,
	pix=FALSE, wmf=FALSE, singles=FALSE, pages=FALSE) {

	assign("PBSfish",list(module="M02_Biology",func="compCsum"),envir=.GlobalEnv)
	#Subfunctions----------------------------------
	createPNG <- function(plotname,rc=c(1,3),rheight=4.5,mar=c(2,2,.5,.5),oma=c(2,1.5,0,0)) {
		plotname <- paste(plotname,"png",sep=".")
		png(plotname, units="in", res=300, width=6.5, height=rheight*rc[1])
		expandGraph(mfrow=rc,mar=mar,oma=oma,mgp=c(1.5,.5,0),cex=0.8) }
	createWMF <- function(plotname,rc=c(1,3),rheight=4.5,mar=c(2,2,.5,.5),oma=c(2,1.5,0,0)) {
		plotname <- paste(plotname,"wmf",sep=".")
		win.metafile(plotname, width=6.5, height=rheight*rc[1])
		expandGraph(mfrow=rc,mar=mar,oma=oma,mgp=c(1.5,.5,0),cex=0.8) }
	csum=function(x,N,yspc=1){ # transform x-data to relative cumulative sums
		pos=attributes(x)$pos; lab=attributes(x)$lab
		if (pro) {
			xy=hist(x,breaks=seq(min(x)-.5,max(x)+.5,1),plot=FALSE)
			x=xy$mids; y=cumsum(xy$density) }
		else {
			x=sort(x); n=length(x); y=(1:n)/n }
		clr=clrs[lab]
		lines(x,y,col=clr)
		x50=median(x); N50=median(N)
		if (x50<N50) {y0=.8; sn=-1; Nvec=N[N<N50]} else {y0=.2; sn=1; Nvec=rev(N[N>=N50])}
		yqnt=y0+sn*(match(lab,names(Nvec))-1)*.04*yspc
		yqnt=max(0,yqnt); yqnt=min(1,yqnt); xqnt=approx(y,x,yqnt,rule=2,ties="ordered")$y
		out=c(xqnt,yqnt); attr(out,"clr")=clr; attr(out,"lab")=lab
		invisible(out) }
	clab=function(coord,delim=""){ # label the curves
		x=coord[1]; y=coord[2]
		clr=attributes(coord)$clr; lab=attributes(coord)$lab
		if (delim!="") {dpos=regexpr(delim,lab); lab=substring(lab,dpos+1)}
		xdif=diff(par()$usr[1:2]); ydif=diff(par()$usr[3:4])
		xoff=0.5*((nchar(lab))^.7*0.1)*(xdif/par()$pin[1])
		yoff=0.5*((1)^.7*0.1)*(ydif/par()$pin[2])
		xbox=x+c(-1,-1,1,1)*xoff; ybox=y+c(-1,1,1,-1)*yoff
		polygon(xbox,ybox,col="ghostwhite",border=clr)
		text(x,y,lab,col=clr,adj=c(ifelse(wmf,.5,.45),ifelse(wmf,.3,.4)),cex=.7) 
		invisible() }
	plotCurve=function(pdat,xfld,yfac,yspc=1) { # plot the relative cumulative curves
		paul=any(yfac==c("area","trip")); gap=!paul
		plot(0,0,type="n",xlab="",ylab="",xlim=xlim,ylim=ylim,axes=FALSE)
		mfg=par()$mfg; nr=mfg[3]
		row1=mfg[1]==mfg[3]; col1=mfg[2]==1
		tck=0.01*sqrt(prod(par()$mfg[3:4]))
		axis(1,labels=gap||row1,tck=-tck)
		axis(2,labels=gap||col1,tck=tck)
		if ((gap&col1) || (!gap&(col1&row1)))
			 mtext("Cumulative Frequency",outer=!gap,side=2,line=2,cex=nr^(-.01))
		if (row1) 
			mtext(paste(toupper(substring(xfld,1,1)),substring(xfld,2),sep=""),outer=!gap,side=1,line=2,cex=1.2)
		if (paul) addLabel(.9,.1,attributes(pdat)$yr,adj=1,cex=ifelse(pix|wmf,.9,1))
		else      addLabel(.9,.1,paste(amat,": trip type (",tmat,")",sep=""),adj=1,cex=ifelse(pix|wmf,.9,1))
		if (nrow(pdat)!=0) {
			ATlist=split(pdat[,xfld],pdat[,yfac]); packList("ATlist","PBSfish")
			z=sapply(ATlist,function(x){length(x[!is.na(x)])}); ATlist=ATlist[z>7]
			if (length(ATlist)!=0) {
				abline(h=.5,col="gainsboro")
				if (pro) N=sort(sapply(ATlist,function(x){median(hist(x,breaks=seq(min(x)-.5,max(x)+.5,1),plot=FALSE)$mids)}))
				else     N=sort(sapply(ATlist,median))
				for (j in 1:length(ATlist)) {
					attr(ATlist[[j]],"pos")=j; attr(ATlist[[j]],"lab")=names(ATlist)[j] }
				lpos=sapply(ATlist,csum,N=N,yspc=yspc,simplify=FALSE)
				sapply(lpos,clab,delim=ifelse(yfac=="area","-",""))
			} else addLabel(.5,.5,cex=1.5,"Scarce Data",col="gainsboro")
		}  else addLabel(.5,.5,cex=1.5,"No Data",col="gainsboro")
		box(); invisible() }
	#----------------------------------Subfunctions

	CLRS=c("red","goldenrod","seagreen","blue","midnightblue") # Master colours
	unpackList(areas,scope="L") # make local all areas specified by user
	fnam=as.character(substitute(dat))
	expr=paste("getFile(",fnam,",scope=\"G\",try.all.frames=TRUE); dat=",fnam,sep="")
	eval(parse(text=expr))

	flds=names(dat)
	attSpp=attributes(dat)$spp
	if (is.null(strSpp) || strSpp=="") {
		if (is.null(attributes(dat)$spp) || attributes(dat)$spp=="") strSpp="999"
		else strSpp=attSpp }
	else if (!is.null(attSpp) && attSpp!=strSpp)
		showError(paste("Specified strSpp '",strSpp,"' differs from species attribute '",attSpp,"' of data file",sep=""))
	if (any(is.element(c("spp","species","sppcode"),flds))) {
		fldSpp=intersect(c("spp","species","sppcode"),flds)[1]
		dat=dat[is.element(dat[,fldSpp],strSpp),] }

	for (i in setdiff(c(xfld,yfac),c("area","trip")))  dat=dat[!is.na(dat[,i]),]
	if  (xfld=="len") dat[,xfld]=dat[,xfld]/10 # change from mm to cm
	nfac=length(yfac)

	aflds=c("major","minor","locality","srfa","srfs","popa")
	yarea=character(0)
	yrfld=intersect(c("year","yr","fyear","fyr"),names(dat))[1]
	if (!is.na(yrfld))
		eval(parse(text=paste(yrfld,"=",deparse(years))))
	
	flds=c("ttype","stype","ameth",yrfld)#,names(areas))
	for (i in flds) {
		expr=paste("dat=biteData(dat,",i,")",sep=""); eval(parse(text=expr))
		if (any(i==aflds)) eval(parse(text=paste("yarea=union(yarea,",i,")"))) }
	if (nrow(dat)==0) {
		if (pix|wmf) return()
		else showError("No records selected for specified qualification") }
	if (!is.null(plus) && plus>0) dat[,xfld][dat[xfld]>=plus]=plus

	if (!allTT) ttype=sort(unique(dat$ttype))
	tlab=sapply(ttype,function(x){paste(paste(x,collapse="+",sep=""),sep="")},simplify=TRUE); ntt=length(tlab)
	alist=sapply(areas,function(x){sapply(x,function(x){paste(x,collapse="+")},simplify=FALSE)},simplify=FALSE)
	alen=sapply(alist,length)
	alab=paste(rep(names(alist),alen),unlist(alist),sep="-"); nar=length(alab)
	aName=paste("-areas(",paste(alab,collapse=","),")",sep="")
	tName=paste("-tt(",paste(tlab,collapse=","),")",sep="")

	xlim=c(0,max(dat[,xfld],na.rm=TRUE)); ylim=c(0,1)
	sex <- list(1,2,1:2,c(0,3),0:3); names(sex) <- c("Males","Females","M+F","Unknown","All")

	# Special Case 1: Compare areas for specified years (thanks Paul)
	if (all(yfac=="area")) { 
		spooler(areas,"area",dat) # creates a column called 'area' and populates based on argument 'areas'.
		dat=dat[!is.na(dat$area),]
		ufac=sort(unique(dat$area))
		clrs=rep(CLRS,length(ufac))[1:length(ufac)]; names(clrs)=ufac
		if (nrow(dat)==0) showError("area","nodata")
		nyr=length(years); sqn=sqrt(nyr); m=ceiling(sqn); n=ceiling(nyr/m) 
		aName=paste("-area(",paste(alab,collapse=","),")",sep="")
		yName=paste("-year(",years[1],"-",years[length(years)],")",sep="")
		plotname <- paste("Csum-",strSpp,aName,tName,yName,sep="")
		mar=c(0,0,0,0); oma=c(4,3.5,.5,.5)
		if (!pix&!wmf) { resetGraph()
			expandGraph(mfrow=c(m,n),mar=mar,oma=oma,mgp=c(1.5,.5,0),cex=0.8) }
		else {
			if (pix)      createPNG(plotname,rc=c(m,n),rheight=3,mar=mar,oma=oma)
			else if (wmf) createWMF(plotname,rc=c(m,n),rheight=3,mar=mar,oma=oma) }
		for (i in years) {
			idat=dat[is.element(dat$year,i),]; attr(idat,"yr")=i
			plotCurve(idat,xfld,"area",yspc=2) }
		if (pix|wmf) dev.off()
		stuff=c("dat","xlim","ylim","ufac","aName","tName","yName","clrs","plotname"); packList(stuff,"PBSfish")
		return(invisible())
	}
	if (all(yfac=="trip")) { # compare trip types for specified years (not implemented)
		spooler(ttype,"trip",dat)
		packList("dat","PBSfish")
		showError("This option not yet implemented")
	}
	aName=paste("-areas(",paste(alab,collapse=","),")",sep="")
	tName=paste("-tt(",paste(tlab,collapse=","),")",sep="")
	fName=paste("-fac(",paste(yfac,collapse=","),")",sep="")
	plotname <- paste("Csum-",strSpp,aName,tName,fName,sep="")

	rc=c(length(alab)*length(tlab),nfac)
	if (!pix&!wmf) { resetGraph()
		expandGraph(mfrow=rc,mar=c(2,2,.5,.5),oma=c(2,1.5,0,0),mgp=c(1.5,.5,0),cex=0.8) }
	else if ((!singles&!pages) && (pix|wmf)) {
		if (pix)      createPNG(plotname,rc=rc)
		else if (wmf) createWMF(plotname,rc=rc) }

	for (a in names(areas)) {
		for (aa in 1:alen[a]) {
			aaa=areas[[a]][[aa]]; assign(a,aaa)
			expr=paste("adat=biteData(dat,",a,")",sep=""); eval(parse(text=expr))
			amat=paste(a,"-",paste(aaa,collapse="+"),sep="")
			aaName <- paste("Csum-",strSpp,"-area(",amat,")",tName,fName,sep="")
			if (pages && pix)      createPNG(aaName,rc=c(length(tlab),nfac))
			else if (pages && wmf) createWMF(aaName,rc=c(length(tlab),nfac))
			for (tt in ttype) {
				tmat=paste(tt,collapse="+")
				tdat <- adat[is.element(adat$ttype,tt),]
				if (nrow(tdat)==0) next
				ttName <- paste("Csum-",strSpp,aName,paste("-tt(",tt,")",sep=""),fName,sep="")
				if (singles && pix) createPNG(ttName,rc=c(1,nfac))
				else if (singles && wmf) createWMF(ttName,rc=c(1,nfac))
				for (i in yfac) {
					ufac=sort(unique(dat[,i]))
					clrs=rep(CLRS,length(ufac))[1:length(ufac)]; names(clrs)=ufac
					plotCurve(tdat,xfld,i,yspc=1) 
				}
				if (singles && (pix|wmf)) dev.off()
			}
			if (pages && (pix|wmf)) dev.off()
	}	}
	if ((!singles&!pages) && (pix|wmf)) dev.off()
	stuff=c("xlim","ylim","alab","tlab","aName","tName","aaName","ttName","clrs","plotname","strSpp"); packList(stuff,"PBSfish")
	invisible() }
#-----------------------------------------compCsum

#estOgive-------------------------------2012-06-13
# Creates ogives of some metric (e.g., % maturity at age).
# Arguments:
#   dat    - specimen morphometrics data from GFBio
#   strSpp - string code for species
#   method - "empir", "logit", "dblnorm"
#   sex    - list of sex codes
#   mos    - list of months when maturity specifications apply: list(Male, Female, All)
#   mat    - codes that define maturity (e.g., 3+)
#   ofld   - ogive field (usually age)
#   obin   - bin size (y) to group ages
#   xlim   - range of morphometric (x-axis)
#-----------------------------------------------RH
estOgive <- function(dat=pop.age, strSpp="", method=c("empir","dblnorm"), sex=list(1,2,1:2), 
     mos=list(1:12,1:12,1:12), mat=3:7, ofld="age", obin=1, xlim=c(0,60), 
     fg=c("blue","red","black"), bg=c("cyan","pink","grey85"), wmf=FALSE, ...) {

#--Subfunctions-------------------------
	pmat <- function(x,mat) { # calculate proportions mature
		n=length(x); xm=x[is.element(x,mat)]; nm=length(xm)
		return(nm/n) }
	fitDN = function(P) { #fit maturity using double normal
		mu=P[1]; nuL=P[2]; nuR=P[3]
		a = obs$mn; pobs=obs$pemp; zL = a<=mu; zR = a>mu
		pred = c( exp(-(a[zL]-mu)^2 / nuL) , exp(-(a[zR]-mu)^2 / nuR) )
		n <- length(pobs); ssq <- sum((pobs-pred)^2 )
		return(n*log(ssq)) }
	calcDN = function(P,a=obs$mn) {
		mu=P[1]; nuL=P[2]; nuR=P[3]
		#a = seq(1,60,len=1000) #a = obs$mn; pobs=obs$pemp; 
		zL = a<=mu; zR = a>mu
		pred = c( exp(-(a[zL]-mu)^2 / nuL) , exp(-(a[zR]-mu)^2 / nuR) )
		return(pred) }
	page = function(p=.5,mu,nu) {
		mu - sqrt(-nu*log(p)) }
	doLab =function(x,y,x50,n=1,...) {
		ldR=unlist(approx(x,y,min(xlim[2],x[length(x)],na.rm=TRUE),rule=2,ties="ordered"))
		#text(ldR[1],ldR[2]+.01*dy,sexlab,cex=0.8,col=fg[s])
		if (x50>xlim[1] & x50<xlim[2]) {
			flagIt(a=x50,b=0.5,r=0.2,A=switch(s,135,315),col=fg[s],n=n,...)
			points(x50,0.5,pch=21,bg=bg[s],cex=1.2)
			#if (above) off=c(-1.10,(s-1)*.015) else off=c(1.10,-(s-2)*.02)
			#text(x50+off[1],.5+off[2],show0(round(x50,1),1,add2int=TRUE),cex=0.8,col=fg[s],srt=0) }
			#text(x50+.015*dx*off[1],.5+.02*dy*off[2],show0(round(x50,1),1,add2int=TRUE),cex=0.8,col=fg[s],srt=0) }
		} else {
			ldL=unlist(approx(x,y,xlim[1],rule=2,ties="ordered"))
			text(ldL[1],ldL[2]+.02*dy,show0(round(ld50,1),1,add2int=TRUE),cex=0.8,col=fg[s]) } }
#--End Subfunctions---------------------

	sexcode=c("Unknown","Male","Female","Indetrminate"); names(sexcode)=0:3

	assign("PBSfish",list(module="M02_Bio",func="estOgive"),envir=.GlobalEnv)
	fnam=as.character(substitute(dat))
	expr=paste("getFile(",fnam,",use.pkg=TRUE,try.all.frames=TRUE,scope=\"G\"); dat=",fnam,sep="")
	eval(parse(text=expr))

	flds=names(dat); 
	need=c(ofld,"date","sex","mat"); if (ofld=="age") need=c(need,"ameth")
	if(!all(is.element(need,flds)))
		showError(setdiff(need,flds),"nofields")

	attSpp=attributes(dat)$spp
	if (is.null(strSpp) || strSpp=="") {
		if (is.null(attributes(dat)$spp) || attributes(dat)$spp=="") strSpp="999"
		else strSpp=attSpp }
	else if (!is.null(attSpp) && attSpp!=strSpp)
		showError(paste("Specified strSpp '",strSpp,"' differs from species attribute '",attSpp,"' of data file",sep=""))
	if (any(is.element(c("spp","species","sppcode"),flds))) {
		fldSpp=intersect(c("spp","species","sppcode"),flds)[1]
		dat=dat[is.element(dat[,fldSpp],strSpp),] }

	if (ofld=="len") dat$len=dat$len/10
	if (ofld=="age") dat=dat[is.element(dat$ameth,3),] # break and burn only
	dat$month <- as.numeric(substring(dat$date,6,7))

	dat$ogive <- dat[,ofld]
	dat <- dat[is.element(dat$sex,sort(unique(unlist(sex)))),]
	dat <- dat[is.element(dat$mat,1:7),]
	dat <- dat[dat$ogive>=xlim[1] & dat$ogive<=xlim[2] & !is.na(dat$ogive),]
	dat$obin <- ceiling(dat$ogive/obin)*obin # - (obin/2) # Mean age of each bin
	names(sex)=sapply(sex,function(x){paste(x,collapse="")})
	if (any(duplicated(names(sex)))) showError("Choose unique combinations of sex")
	nsex=length(sex)
	mos=rep(mos,nsex)[1:nsex]; fg=rep(fg,nsex)[1:nsex]; bg=rep(bg,nsex)[1:nsex]

	abin <- split(dat$mat,dat$obin)	
	x = as.numeric(names(abin))
	xpos = x - (obin-1)*.5   # mid-point of binned ogive
	if (is.null(xlim)) xlim = range(xpos); 
	dx <- diff(xlim)
	out = array(NA,dim=c(length(names(abin)),6,nsex),
		dimnames=list(bin=names(abin),val=c("pemp","n","mn","sd","pbin","pdbl"),sex=names(sex)))
	ylim <- c(0,1); dy <- diff(ylim)
	pend=list()

	for (s in 1:nsex) {
		ss=names(sex)[s]
		above=as.logical(s%%2); print(c(s,above))
		sexlab=paste(substring(sexcode[as.character(sex[[s]])],1,1),collapse="+")

		sdat <- dat[is.element(dat$sex,sex[[s]]),]
		sdat <- sdat[is.element(sdat$month,mos[[s]]),]
		mbin <- split(sdat$mat,sdat$obin)	
		x = as.numeric(names(mbin))
		xpos = x - (obin-1)*.5   # mid-point of binned ogive

		# binomial logit fit
		sdat$bmat = as.numeric(is.element(sdat$mat,mat)) # T/F for mature
		pdat = sdat[,c("obin","bmat")]
		pout = fitLogit(pdat,"bmat","obin")
		coeffs = pout$coefficients
		a=coeffs[1]; b=coeffs[2]
		pbin = exp(a+b*xpos)/(1+exp(a+b*xpos)); names(pbin)=x
		out[names(pbin),"pbin",ss]=pbin
		ybin=seq(.01,.99,.01)
		xbin=(log(ybin/(1-ybin))-a)/b
		ld50=-a/b

		# empirical fit
		pemp  = sapply(mbin,pmat,mat=mat)   # empircal proportions mature
		ogive = split(sdat$ogive,sdat$obin) # age/lengths in the bin
		n     = sapply(ogive,length)        # number of ages/lengths in bin
		mn    = sapply(ogive,mean)          # mean age/length by bin
		sd    = sapply(ogive,sd)            # std dev of mean age/length by bin
		out[names(pemp),"pemp",ss]=pemp
		out[names(n),"n",ss]=n; out[names(mn),"mn",ss]=mn; out[names(sd),"sd",ss]=sd
		eval(parse(text="obs <<- list(mn=mn, pemp=pemp)"))
		mdx <- approx(pemp,mn,xout=.5,rule=2,ties="ordered")$y

		# double normal fit
		parVec = data.frame(val=c(15,0.9,exp(100)),min=c(5,0.1,exp(10)),max=c(60,100,exp(150)),active=c(TRUE,TRUE,FALSE),
			row.names=c("mu","nuL","nuR"), stringsAsFactors=FALSE)
		dlist = calcMin(pvec=parVec,func=fitDN,method="nlm",repN=10)
		Pend  = dlist$Pend
		p50 = page(0.5,Pend[[1]],Pend[[2]])
		pend[[ss]] = c(Pend,p50=p50)
		ydbl = calcDN(Pend)
		xdbl = as.numeric(names(ydbl))
		out[names(ydbl),"pdbl",ss]=ydbl
		out[names(n),"n",ss]=n; out[names(mn),"mn",ss]=mn; out[names(sd),"sd",ss]=sd

		if (s==1) {
			if (wmf) win.metafile(paste("Ogive-",ofld,".wmf",sep=""),height=4,width=8)
			else resetGraph()
			expandGraph(mfrow=c(1,1),mai=c(.6,.7,0.05,0.05),omi=c(0,0,0,0),las=1,lwd=1)
			plot(xpos,pemp,type="n",xlab="",ylab="",xaxt="n",yaxt="n",xlim=xlim,ylim=c(0,1))
			abline(h=.5,col="gainsboro",lty=1,lwd=2)
			if(ofld=="age") axis(1,at=seq(floor(xlim[1]),ceiling(xlim[2]),1),tcl=-.2,labels=FALSE)
			axis(1,at=seq(floor(xlim[1]),ceiling(xlim[2]),5),tcl=-.4,labels=FALSE)
			axis(1,at=seq(floor(xlim[1]),ceiling(xlim[2]),10),tcl=-.5,mgp=c(0,.5,0),cex=.9)
			axis(2,at=seq(0,1,.05),tcl=-.25,labels=FALSE)
			axis(2,at=seq(0,1,.1),tcl=-.5,mgp=c(0,.7,0),cex=.9,adj=1)
			mtext(ifelse(ofld=="age","Age","Length"),side=1,cex=1.2,line=1.75)
			mtext("Proportion Mature",side=2,cex=1.2,line=2.5,las=0) }

		nmeth = 0
		if (any(method=="logit")) {
			nmeth = nmeth + 1
			lines(xbin,ybin,col=fg[s],lwd=ifelse(all(method=="logit"),2,1),lty=ifelse(all(method=="logit"),1,3))
			doLab(xbin,ybin,ld50,n=nmeth,...) 
		}
		if (any(method=="dblnorm")) {
			nmeth = nmeth + 1
			Xdbl=seq(xlim[1],xlim[2],len=1000)
			Ydbl=calcDN(Pend,a=Xdbl)
			lines(Xdbl,Ydbl,col=fg[s],lwd=ifelse(all(method=="dblnorm"),2,2),lty=ifelse(all(method=="dblnorm"),1,1))
			doLab(Xdbl, Ydbl,p50,n=nmeth,...)
		}
		if (any(method=="empir")) {
			nmeth = nmeth + 1
			points(mn,pemp,pch=20,col=fg[s],cex=1.2)
			#if (all(method=="empir")) {
				lines(mn,pemp,col=fg[s])
				mdxy <- approx(pemp,mn,xout=.5,rule=2,ties="ordered")
				mdx=mdxy$y; mdy=mdxy$x
				doLab(mn,pemp,mdx,n=nmeth,...)
			#}
		}
	}
	addLegend(.7,.3,legend=paste("sex",sapply(strsplit(names(sex),""),paste,collapse="+")),lwd=ifelse(any(method==c("logit","dblnorm")),2,1),
		pch=ifelse(any(method=="empir"),20,NA),col=fg[1:length(sex)],cex=1.2,bty="n")
	box()
	if(wmf) dev.off()
	stuff=c("mdxy","mbin","ld50","ldR","ldL","out","pmat","obin","strSpp","pend")
	packList(stuff,"PBSfish")

	fout=paste(fnam,"-sex(",paste(names(sex),collapse="+"),").csv",sep="")
	data(species)
	cat(paste("Maturity ogives:",species[strSpp,"name"],"\n"),file=fout)
	for (s in 1:nsex) {
		ss=names(sex)[s]
		sout=out[,,ss]
		cat(paste("sex:",ss,"\n"),file=fout,append=TRUE)
		cat("age,",paste(colnames(sout),collapse=","),"\n",file=fout,append=TRUE)
		svec=apply(sout,1,paste,collapse=",")
		cat(paste(paste(names(svec),svec,sep=","),collapse="\n"),"\n",file=fout,append=TRUE)
	}
	invisible() }
#-----------------------------------------estOgive

#genPa----------------------------------2011-09-15
# Generate proportions-at-age using the catch curve 
# composition of Schnute and Haigh (2007, Table 2).
#   np    : number of age classes
#   theta : {Z, mu, sigma, bh, rho, tau}
#   sim   : logical, if TRUE return components of the simulated proportions-at-age.
#-------------------------------------------JTS/RH
genPa <- function(np=40, 
     theta=list(Z=0.1,mu=15,sigma=5,bh=c(10,20),rho=c(3,2),tau=1.5), sim=TRUE) {
	unpackList(theta)
	if (length(bh)!=length(rho))
		showError("Lengths of 'bh' and 'rho'\n(ages at and magnitudes of recruitment anomalies, respectively)\nmust be the same",as.is=TRUE)
	if (sim)
		assign("PBSfish",list(module="M02_Biology",call=match.call(),np=np,theta=theta),envir=.GlobalEnv)
	m  = length(bh)                                # number of recruitment anomalies
	B  = np; a  = 1:B                              # maximum age used in model
	Sa = GT0(exp(-Z*a))                            # survival (T2.1)
	Ba = rep(1.0,B)                                # initialise the selectivity vector
	Ba[a<mu] = exp(-(a[a<mu]-mu)^2 / sigma^2)      # selectivity (F.7, POP 2010, left side of double normal)
	Ba = GT0(Ba)                                   # make sure selectivity at age is always greater than zero
	Rm = vector("numeric",B)                       # initialise the recruitment vector
	for (i in 1:m)
		Rm = Rm+rho[i]*exp(-0.5*((a-bh[i])/tau)^2)  # combined effect of recruitment anomalies (T2.3)
	Ra = 1 + Rm                                    # recruitment effect (T2.3)
	pa = Sa*Ba*Ra; pa = pa/sum(pa)                 # aggrgegation of survival, selectivity, and recruitment (T2.4)
	if (sim) {
		om =c("Sa","Ba","Ra","pa")
		for (i in om) eval(parse(text=paste("PBSfish$",i,"<<-",i,sep=""))) }
	return(pa) }
#--------------------------------------------genPa

#histMetric-----------------------------2009-11-09
# Create a matrix of histograms for a specified metric
#-----------------------------------------------RH
histMetric <- function(dat=pop.age, xfld="age", xint=1, minN=50,
	ttype=1:4, year=NULL, plus=NULL, ptype="bars", allYR=FALSE, allTT=FALSE,
	major=NULL, minor=NULL, locality=NULL, srfa=NULL, srfs=NULL,
	xlim=NULL, ylim=NULL, pxlab=c(.075,.85),axes=TRUE,
	fill=FALSE, bg="grey90", fg="black", 
	hrow=0.75, hpage=8, wmf=FALSE, pix=FALSE) {

	xlab=ifelse(xfld=="len","Length (cm)",ifelse(xfld=="age","Age (y)","Metric"))
	assign("PBSfish",list(module="M02_Biology",func="histMetric",xlab=xlab),envir=.GlobalEnv)
	dat=as.character(substitute(dat)); spp=substring(dat,1,3)
	expr=paste("getFile(",dat,",use.pkg=TRUE,try.all.frames=TRUE,scope=\"G\"); dat=",dat,sep="")
	eval(parse(text=expr))
	dat$x=dat[,xfld]; dat=dat[!is.na(dat$x),]
	if(any(ttype==14)) dat$ttype[is.element(dat$ttype,c(1,4))]=14
	if(any(ttype==23)) dat$ttype[is.element(dat$ttype,c(2,3))]=23

	areas=c("major","minor","locality","srfa","srfs"); yarea=character(0)
	flds=c("year","ttype",areas)
	for (i in flds) {
		expr=paste("dat=biteData(dat,",i,")",sep=""); eval(parse(text=expr))
		if (any(i==areas)) eval(parse(text=paste("yarea=union(yarea,",i,")"))) }
	if (nrow(dat)==0) {
		if (wmf) return()
		else showError("No records selected for specified qualification") }
	ylab=paste(ifelse(ptype=="csum","Cumulative","Relative"),"Frequency",
		ifelse(length(yarea)==0,"",paste("(areas: ",paste(yarea,collapse=","),")",sep="")))
	if (!allTT) ttype=sort(unique(dat$ttype))
	ntt=length(ttype)

	if(xfld=="len") { dat$x=dat$x/10 } #; dat=dat[dat$x<=70,] }
	if (!is.null(plus) && plus>0) dat$x[dat$x>=plus]=plus
	dat$xbin = ceiling(dat$x/xint) * xint
	if (is.null(xlim)) xlim=c(0,max(dat$xbin))
	xpos=pretty(xlim,n=10); xpos=xpos[xpos>=0]

	xy=as.list(ttype); names(xy)=ttype
	if (ptype=="csum") ylim=c(0,1)
	if (is.null(ylim)) {ylim=c(0,-Inf); calcylim=TRUE} else calcylim=FALSE
	YRS=NULL
	for (i in ttype) {
		ii=as.character(i)
		idat=dat[is.element(dat$ttype,i),]
		bdat=split(idat$xbin,idat$year) # binned data
		xdat=split(idat$x,idat$year) # original data
		N=sapply(bdat,length)
		z=N>=minN; bdat=bdat[z]; 
		yrs=as.numeric(names(bdat)); nyr=length(yrs)
		YRS=union(YRS,yrs); NYR=length(YRS)
		xy[[ii]]=as.list(yrs); names(xy[[ii]])=yrs
		for (j in yrs) {
			jj=as.character(j)
			jdat=bdat[[jj]]
			bins=split(jdat,jdat)
			y=sapply(bins,length); Y=sum(y); y=y/Y; 
			x=as.numeric(names(y))
			if (calcylim) {ylim[1]=min(y,ylim[1]); ylim[2]=max(y,ylim[2])}
			xy[[ii]][[jj]] = list(x=x,y=y,n=Y,mn=mean(xdat[[jj]]))
		}
	}
	ypos=pretty(ylim,n=5); #ypos=ypos[-1]
	YRS=sort(YRS)
	if (allYR) {
		if (!is.null(year)) YRS=min(year):max(year)
		else YRS=YRS[1]:YRS[length(YRS)] }
	NYR=length(YRS)

	if (ntt==1) {
		rc=PBSmodelling:::.findSquare(NYR)
		m=rc[1]; n=rc[2] }
	else {
		m=NYR; n=ntt }
	fnam=paste(spp,"-",xfld,"-",ptype,"-tt",paste(ttype,collapse=""),
		"-bin",xint,"-year(",YRS[1],"-",YRS[NYR],")",ifelse(length(yarea)==0,"",paste("-area(",
		paste(yarea,collapse=","),")",sep="")),sep="")
	if (wmf) win.metafile(paste(fnam,".wmf",sep=""),width=6.5,height=min(hrow*m,hpage))
	else if (pix) png(paste(fnam,".png",sep=""),units="in",res=300,width=6.5,height=min(hrow*m,hpage))
	else resetGraph()

	if (ntt==1)
		expandGraph(mfrow=c(ifelse(wmf,n,m),ifelse(wmf,m,n)),mar=c(0,0,0,0),oma=c(4,5,0.5,0.5))
	else
		expandGraph(mfcol=c(m,n),mar=c(0,0,0,0),oma=c(4,ifelse(axes,5,2),2,0.5))
	for (i in ttype) {
		ii=as.character(i)
		tlab=c("Non-Obs Comm","Research","Charter","Obs Comm","Commercial","Research")
		names(tlab)=c(1:4,14,23)
		for (j in YRS) {
			jj=as.character(j)
			xyij=xy[[ii]][[jj]]
			if (is.null(xyij)) 
				plot(0,0,type="n",xlim=xlim,ylim=ylim,xaxt="n",yaxt="n",xlab="",ylab="",axes=axes)
			else {
				x=xyij$x; y=xyij$y; n=xyij$n; mn=xyij$mn
				if (ptype=="csum") y=cumsum(y)
				plot(x,y,type="n",xlim=xlim,ylim=ylim,xaxt="n",yaxt="n",xlab="",ylab="",axes=axes)
				abline(h=ypos,v=xpos,col="grey95")
				if (ptype=="bars") {
					if (fill) {
						xpol=as.vector(sapply(x,function(x,xoff){c(x+c(-xoff,xoff,xoff,-xoff),NA)},xoff=xint/2))
						ypol=as.vector(sapply(y,function(y,base){c(base,base,y,y,NA)},base=0))
						polygon(xpol,ypol,col=bg,border=fg) }
					else
						drawBars(x,y,width=xint) }
				else if (ptype=="csum") {
					md=approx(y,x,.5,rule=2,ties="ordered")$y
					lines(x,y,col=fg) 
					points(md,.5,pch=21,bg=bg,cex=1.2)
					text(md+2,.5,round(md,1),adj=0,cex=1.2/sqrt(m^0.1)) }
				else if (ptype=="vlin") lines(x,y,type="h",col=fg)
			}
			if (axes | par()$mfg[1]==par()$mfg[3])
				axis(1,at=xpos,cex.axis=1.2,tck=.01,mgp=c(0,.5,0),labels=ifelse(par()$mfg[1]==par()$mfg[3],TRUE,FALSE))
			if (axes)
			axis(2,at=ypos,las=1,cex.axis=1+1/m,tck=.02,adj=1,mgp=c(0,.5,0),
				labels=ifelse(par()$mfg[2]==1 && par()$mfg[1]%%2==1,TRUE,FALSE))
			if (ntt==1 || par()$mfg[2]==1)
				addLabel(.06,.95,jj,adj=c(0,1),col="blue",cex=1.5/(m^0.1))
			if (ntt>1 && par()$mfg[1]==1)
				mtext(tlab[ii],side=3,line=0.2,col="blue",cex=.8)
			if (axes && !is.null(xyij)) 
				addLabel(pxlab[1],pxlab[2],paste("n",n,ifelse(ptype=="csum","",
					paste(",",toupper(substring(xfld,1,1)),round(mn)))),adj=c(0,1),col="green4",cex=1.2/(m^0.1)) 
			if (axes) box()
		} # end j loop
	} # end i loop
	mtext(xlab,outer=TRUE,side=1,las=1,line=2.5,cex=1.25)
	mtext(ylab,outer=TRUE,side=2,las=0,line=ifelse(axes,3.25,.25),cex=1.25)
	if (wmf|pix) dev.off()

	stuff=c("dat","xy","YRS","ttype","xlim","ylim"); packList(stuff,"PBSfish")
	invisible() }
#---------------------------------------histMetric

#histTail-------------------------------2009-07-17
# Create a histogram showing tail details
#-----------------------------------------------RH
histTail <-function(dat=pop.age, xfld="age", tailmin=NULL, 
      bcol="gold", tcol="moccasin", hpage=3.5, 
      wmf=FALSE, pix=FALSE, ...) {

	assign("PBSfish",list(module="M02_Biology",func="histTail"),envir=.GlobalEnv)
	dat=as.character(substitute(dat))
	expr=paste("getFile(",dat,",use.pkg=TRUE,try.all.frames=TRUE); dat=",dat,sep="")
	eval(parse(text=expr))
	if (!require(MASS, quietly=TRUE)) showError("MASS package is required for 'truehist'")

	prob=zoomprob=list(...)[["prob"]]
	if(is.null(prob)) { prob=TRUE; zoomprob=FALSE }
	x = dat[,xfld]; x = x[!is.na(x)]; nx=length(x)
	xlab = paste(toupper(substring(xfld,1,1)),substring(xfld,2),sep="",collapse=" ")
	spp = attributes(dat)$spp
	fnam=paste(spp,"-Hist-",xlab,sep="")
	if (wmf) win.metafile(paste(fnam,".wmf",sep=""),width=6.5,height=hpage)
	else if (pix) png(paste(fnam,".png",sep=""),units="in",res=300,width=6.5,height=hpage)
	else resetGraph()
	expandGraph(mfrow=c(1,1),mar=c(3,5,.5,.5),oma=c(0,0,0,0),las=1,xaxs="i",yaxs="i")
	
	evalCall(truehist,argu=list(data=x,col=bcol,cex.lab=1.2,xlab=xlab),...,checkpar=TRUE)
	ylab=paste(ifelse(prob,paste(ifelse((wmf|pix)&&hpage<4.5,"Rel. Freq.","Relative Frequency"),
		" Density"),"Frequency")," ( N = ",format(nx,scientific=FALSE,big.mark=",")," )",sep="")
	mtext(ylab,side=2,line=3.5,cex=1.2,las=0)
	if (!is.null(tailmin)){
		z = x>=tailmin & !is.na(x); nz=sum(z)
		brks=((tailmin-1):max(x[z]))+.5
		par(new=TRUE,plt=c(.65,.95,.5,.8))
		evalCall(hist,argu=list(x=x[z],breaks=brks,probability=zoomprob,col=tcol,
			main="Tail details",col.main="grey70",mgp=c(1.75,.5,0),xlab=xlab,
			las=ifelse(zoomprob,0,1)),...,checkdef=TRUE,checkpar=TRUE)
		addLabel(.95,.7,paste("Max age = ",max(x[z]),"\nn = ",nz,sep=""),col="grey60",cex=.8,adj=1)
	}
	if (wmf|pix) dev.off()
	stuff=c("x","nx","nz","brks","xlab","ylab"); packList(stuff,"PBSfish")
	invisible() }
#-----------------------------------------histTail

#mapMaturity----------------------------2009-11-10
# Plot maturity chart to see relative occurrence
# of maturity stages by month.
#-----------------------------------------------RH
mapMaturity <- function (dat=pop.age, strSpp="", mats=1:7, sex=1:2, 
		brks=c(0,.05,.1,.25,.5,1),
		clrs=c("aliceblue","lightblue","skyblue3","steelblue4","black"),
		hpage=6, wmf=FALSE, pix=FALSE) {

	assign("PBSfish",list(module="M02_Biology",func="mapMaturity"),envir=.GlobalEnv)
	fnam=as.character(substitute(dat))
	expr=paste("getFile(",fnam,",use.pkg=TRUE,try.all.frames=TRUE,scope=\"G\"); dat=",fnam,sep="")
	eval(parse(text=expr))

	flds=names(dat)
	attSpp=attributes(dat)$spp
	if (is.null(strSpp) || strSpp=="") {
		if (is.null(attributes(dat)$spp) || attributes(dat)$spp=="") strSpp="999"
		else strSpp=attSpp }
	else if (!is.null(attSpp) && attSpp!=strSpp)
		showError(paste("Specified strSpp '",strSpp,"' differs from species attribute '",attSpp,"' of data file",sep=""))
	if (any(is.element(c("spp","species","sppcode"),flds))) {
		fldSpp=intersect(c("spp","species","sppcode"),flds)[1]
		dat=dat[is.element(dat[,fldSpp],strSpp),] }

	mat1 <- c("Immature","Maturing","Developing","Developed","Running","Spent","Resting") # males
	mat2 <- c("Immature","Maturing","Mature","Fertilized","Embryos","Spent","Resting") # females
	nsex <- length(sex)
	mday <- c(31,28,31,30,31,30,31,31,30,31,30,31)
	mcut <- c(0,cumsum(mday))

	ncut <- length(brks)
	lout <- paste(show0(brks[1:(ncut-1)],2),show0(brks[2:ncut],2),sep="-")

	dat <- dat[is.element(dat$mat,mats),]
	dat$month <- as.numeric(substring(dat$date,6,7))
	dat$day   <- as.numeric(substring(dat$date,9,10))

	xlim <- c(1,360)
	ylim <- -rev(range(mats)) + c(-1,.6)
	xpos <- (mcut[1:12]+mcut[2:13])/2
	yspc <- .4

	fnam=paste(strSpp,"-Mats",sep="")
	if (wmf) win.metafile(paste(fnam,".wmf",sep=""), width=8.5, height=hpage)
	else if (pix) png(paste(fnam,".png",sep=""),units="in",res=300,width=8.5,height=hpage)
	else resetGraph()
	par(mfrow=c(nsex,1),mar=c(0,4.5,0,0),oma=c(1,0,3,0))

	for (s in sex) {
		sdat <- dat[is.element(dat$sex,s),]
		plot(0,0,type="n",xlim=xlim,ylim=ylim,xlab="",ylab="",axes=FALSE)
		axis(1,at=xpos,labels=month.abb,tick=FALSE,pos=-7.25,cex=1.2)
		mcode <- get(paste("mat",s,sep=""))
		axis(2,at=-mats,labels=mcode[mats],adj=1,cex=1.2,tick=FALSE,pos=xlim[1],las=1)

		for (i in mats) {
			idat <- sdat[is.element(sdat$mat,i),]
			if (nrow(idat)==0) next
			ibin <- split(idat$day,idat$month)
			icnt <- sapply(ibin,length)
			icnt <- icnt/sum(icnt)
			iclr <- as.numeric(cut(icnt,breaks=brks)); names(iclr)=names(icnt)

			for (j in 1:length(iclr)) {
				jj  <- iclr[j]
				jjj <- as.numeric(names(jj))
				x   <- c(mcut[jjj],mcut[jjj+1],mcut[jjj+1],mcut[jjj])
				y   <- rep(i,4) + c(-yspc,-yspc,yspc,yspc); y <- -y
				polygon(x,y,col=clrs[jj],border=1) }
		}
	}
	par(new=TRUE,mfrow=c(1,1),mar=c(0,0,0,0),oma=c(0,0,0,0)); frame()
	if (any(sex==1)) addLabel(0.02,0.93,"Males",col="blue",cex=1.2,adj=c(0,1))
	if (any(sex==2)) addLabel(0.02,ifelse(nsex==1,.93,.49),"Females",col="darkgreen",cex=1.2,adj=c(0,1))
	addLabel(0.5,0.99,"Relative Frequency",cex=1.2,adj=c(.5,1))
	addLegend(0.2,switch(nsex,0.94,0.96),legend=lout,fill=clrs,cex=0.9,horiz=TRUE,bty="n")
	if (wmf|pix) dev.off()
	stuff=c("xlim","ylim","x","y","sdat","mday","mcut","idat","ibin","icnt","iclr","strSpp"); packList(stuff,"PBSfish")
	par(new=FALSE); invisible() }
#--------------------------------------mapMaturity

#plotProp-------------------------------2010-10-20
# Plot proportion-at-age (or length) from GFBio specimen data.
#-----------------------------------------------RH
plotProp <- function(fnam="pop.age",hnam=NULL,...) {
	assign("PBSfish",list(module="M02_Biology",func="plotProp",plotname="Rplot"),envir=.GlobalEnv)
	fnam=as.character(substitute(fnam))
	if (!is.character(fnam)) stop("Argument 'fnam' must be a string name of an R dataset")
	if (!require(PBSmodelling, quietly=TRUE)) stop("PBSmodelling package is required")
	if (!require(PBStools, quietly=TRUE)) stop("PBStools package is required")
	options(warn=-1)
	data(spn)

	path <- paste(system.file(package="PBStools"),"/win",sep=""); 
	rtmp <- tempdir(); rtmp <- gsub("\\\\","/",rtmp)
	wnam <- paste(path,"plotPropWin.txt",sep="/")
	wtmp <- paste(rtmp,"plotPropWin.txt",sep="/")
	temp <- readLines(wnam)
	temp <- gsub("@wdf",wtmp,temp)
	temp <- gsub("@fnam",fnam,temp)
	if (!is.null(hnam) && is.character(hnam))
		temp <- gsub("#import=",paste("import=\"",hnam,"\"",sep=""),temp)
	writeLines(temp,con=wtmp)
	createWin(wtmp)
	invisible() }

#.plotProp.calcP------------------------2010-10-20
# Perform calculations to get proportions.
#-----------------------------------------------RH
.plotProp.calcP <- function() {
	getWinVal(winName="window",scope="L")
	expr=paste("getFile(",fnam,",use.pkg=TRUE,try.all.frames=TRUE,scope=\"G\"); dat=",fnam,sep="")
	eval(parse(text=expr))
	fspp=attributes(dat)$spp
	if (!is.null(fspp) && fspp!=spp) { spp=fspp; setWinVal(list(spp=fspp)) }
	xy <- as.character(XYopt[,"fld"])
	XLIM <- unlist(XYopt[1,c("lim1","lim2")])
	YLIM <- unlist(XYopt[2,c("lim1","lim2")]);
	xint <- unlist(XYopt[1,"int"]); yint <- unlist(XYopt[2,"int"])

	#  Check available fields
	flds <- names(dat); fldstr <- paste("(",paste(flds,collapse=","),")",collapse="")
	if (!all(is.element(xy,flds)==TRUE)) {
		if (xy[1]=="year" && any(is.element(flds,"date")==TRUE)) {
			dat$year <- as.numeric(as.character(years(dat$date)))
			flds <- c(flds,"year") }
		if (!all(is.element(xy,flds)==TRUE)) 
			showError(str=paste(paste(xy[!is.element(xy,flds)],collapse=","),"in",fldstr,sep="\n"),type="nofields")
	}
	if (!is.null(strat) && strat!="" && !is.element(strat,flds))
		showError(paste(strat,"in",fldstr,sep="\n"),"nofields")
	if (bbonly && !any(flds=="ameth"))
		showError(paste("ameth","in",fldstr,sep="\n"),"nofields")

	# Get the qualifiers
	lister <- function(vec) {
		out <- list(vec);
		for (i in 1:length(vec)) out[i+1] <- vec[i]
		return(out) }
	Msex <- c(1,2,3,0)
	if (all(Usex==FALSE)) sex <- NULL 
	else sex <- sort(unique(unlist(lister(Msex)[Usex])))
	Mgear <- c(0,1,5)
	if (all(Ugear==FALSE)) gear <- NULL 
	else gear <- sort(unique(unlist(lister(Mgear)[Ugear])))
	Mttype <- 1:4
	if (all(Uttype==FALSE)) ttype <- NULL 
	else ttype <- sort(unique(unlist(lister(Mttype)[Uttype])))
	Mstype <- c(0,1,2,4)
	if (all(Ustype==FALSE)) stype <- NULL 
	else stype <- sort(unique(unlist(lister(Mstype)[Ustype])))
	Mmajor <- 3:9
	if (all(Umajor==FALSE)) major <- NULL 
	else major <- sort(unique(unlist(lister(Mmajor)[Umajor])))
	Msrfa <- c("3C","3D","5AB","5CD","5EN","5ES")
	if (all(Usrfa==FALSE)) srfa <- NULL 
	else srfa <- sort(unique(unlist(lister(Msrfa)[Usrfa])))
	Msrfs <- c("GS","MI","MR")
	if (all(Usrfs==FALSE)) srfs <- NULL 
	else srfs <- sort(unique(unlist(lister(Msrfs)[Usrfs])))

	#  Qualify the data
	qflds=c("spp","sex","ttype","stype","gear","major","srfa","srfs")
	for (i in qflds) {
		expr=paste("dat=biteData(dat,",i,")",sep=""); eval(parse(text=expr)) 
		if (nrow(dat)==0) showError(paste("No data for '",i,"' chosen",sep="")) }
	if (bbonly) {
		dat <- dat[is.element(dat$ameth,3),]
		if(nrow(dat)==0) showError("spp:ttype:stype:gear:area:ameth","nodata")  }

	# Reconfigure the X,Y data
	dat$X <- dat[,xy[1]]; dat$Y <- dat[,xy[2]]
	dat   <- dat[!is.na(dat$X) & !is.na(dat$Y),]
	if(nrow(dat)==0) showError(paste(xy,collapse=","),"nodata")
	if (is.na(YLIM[2])) YLIM[2] <- max(dat$Y)
	ylo <- dat$Y < YLIM[1]; yhi <- dat$Y > YLIM[2]
	if (agg) {
		dat$Y[ylo] <- rep(YLIM[1],length(ylo[ylo==TRUE]))
		dat$Y[yhi] <- rep(YLIM[2],length(yhi[yhi==TRUE])) }
	else  dat <- dat[!ylo & !yhi,]

	dat$x <- ceiling(dat$X/xint) * xint
	dat$y <- ceiling(dat$Y/yint) * yint
	xlim <- range(dat$x,na.rm=TRUE); ylim <- range(dat$y,na.rm=TRUE) # actual data ranges
	
	if (is.na(XLIM[1]) | is.na(XYopt[1,2])){ 
		XLIM[1] <- xlim[1]; setWinVal(list("XYopt[1,2]d"=xlim[1]),winName="window") }
	if (is.na(XLIM[2]) | is.na(XYopt[1,3])){ 
		XLIM[2] <- xlim[2]; setWinVal(list("XYopt[1,3]d"=xlim[2]),winName="window") }
	xval <- seq(xlim[1],xlim[2],xint)
	dat <- dat[is.element(dat$x,xval),]
	if (nrow(dat)==0) showError(paste(xlim[1],"to",xlim[2]),"nodata")

	if (is.na(YLIM[1]) | is.na(XYopt[2,2])){ 
		YLIM[1] <- ylim[1]; setWinVal(list("XYopt[2,2]d"=ylim[1]),winName="window") }
	if (is.na(YLIM[2]) | is.na(XYopt[2,3])){ 
		YLIM[2] <- ylim[2]; setWinVal(list("XYopt[2,3]d"=ylim[2]),winName="window") }
	yval <- seq(ylim[1],ylim[2],yint)
	dat <- dat[is.element(dat$y,yval),]
	if (nrow(dat)==0) showError(paste(ylim[1],"to",ylim[2]),"nodata")
	yy <- dat$y # cause R now strips names from data.frame columns
	if (!is.null(strat) && strat!="") names(yy) <- dat[,strat]
	else {names(yy) <- dat$x; setWinVal(list(strat=as.character(XYopt[1,1])),winName="window") }

	# Construct the z-value matrix
	zmat <- array(0,dim=c(length(xval),length(yval),2),dimnames=list(xval,yval,c("count","prop")))
	names(dimnames(zmat)) <- c(xy,"prop")
	tcount=list(); tprop=list()
	lenv=sys.frame(sys.nframe())

	freak <- function(x,w=FALSE) { # stratified weighted frequency (3/7/08)
		ages  <- sort(unique(x))
		strat <- sort(unique(names(x))); snum <- as.numeric(strat); n=length(strat)
		stab  <- array(0,dim=c(length(ages),length(strat)),dimnames=list(ages,strat))
		flist <- split(x, x)
		for (i in names(flist)) {
			nst <- sapply(split(flist[[i]],names(flist[[i]])),length,simplify=TRUE)
			stab[i,names(nst)] <- nst }
		prop <- sweep(stab,2,apply(stab,2,sum),"/") # convert numbers to proportions
		if (w) p=snum/sum(snum)
		else p=rep(1/n,n) # determine proportional weighting
		wprop <- apply(prop,1,function(x,w){sum(x*w)},w=p)
		fcount <- apply(stab,1,sum)
		assign("tcount",c(tcount,list(fcount)),envir=lenv)
		assign("tprop",c(tprop,list(wprop)),envir=lenv)
		return(wprop) }

	nSID   <- sapply(sapply(split(dat$SID,dat$x),unique,simplify=FALSE),length);
	ylist  <- split(yy,dat$x)
	ycount <- sapply(ylist,freak,w=wted,simplify=FALSE)
	yrStr=names(tcount)=names(tprop)=names(ylist)

	for (i in yrStr) {
		zmat[i,names(tcount[[i]]),"count"] <- tcount[[i]]
		zmat[i,names(tprop[[i]]),"prop"]   <- tprop[[i]]  }
	pa <- array(t(zmat[,,"prop"]),dim=c(length(yval),length(xval)),dimnames=list(yval,xval)) 
	Na <- array(t(zmat[,,"count"]),dim=c(length(yval),length(xval)),dimnames=list(yval,xval))
	for (i in c("sex","ttype","stype")) { # actually left in data file
		ui=sort(unique(dat[,i])); ui=setdiff(ui,c("",NA))
		if (length(ui)==0) ui=""
		else eval(parse(text=paste(i,"=c(",paste(ui,collapse=","),")"))) }
	areas=c(major,srfa,srfs); if (is.null(areas)) areas="all"

	stuff=c("dat","flds","XLIM","xlim","YLIM","ylim","xval","yval","zmat",
			"freak","nSID","ylist","ycount","pa","Na","xy","yy","sex","ttype","stype","areas")
	packList(stuff,"PBSfish")
	.plotProp.plotP()
	invisible }

#.plotProp.plotP------------------------2010-10-20
# Guts of the plotting routine.
#-----------------------------------------------RH
.plotProp.plotP <- function(wmf=FALSE) {                # Start blowing bubbles
	sordid <- function(x, lab="wot", count=TRUE) { # count and classify specimens
		z <- is.element(x,c("",NA,NaN))
		x <- x[!z]; if(length(x)==0) return("");
		xcnt <- sapply(split(x,x),length)
		if (count)  xstr <- paste(paste(names(xcnt)," (",xcnt,")",sep=""),collapse=", ")
		else        xstr <- paste(names(xcnt),collapse=",")
		xstr <- paste(lab,": ",xstr,sep="");
		return(xstr) }
	darken <- function(col) { # choose the predominant RGB colour and darken it
		RGB = col2rgb(col)
		x = as.vector(RGB); names(x) = row.names(RGB)
		dom = names(rev(sort(x)))[1]
		paste("dark",dom,sep="") }
	plaster =function(x,sep="",enc=c("(",")")) { # paste together unique values
		if (is.null(x) || all(x=="")) return(NULL)
		lab=as.character(substitute(x))
		ux=sort(unique(x)); ux=setdiff(ux,c("",NA))
		paste(lab,enc[1],paste(ux,collapse=sep),enc[2],sep="") }

	if (is.null(PBSfish$xy)) .plotProp.calcP()
	act <- getWinAct()[1]; 
	if (!is.null(act) && act=="wmf") wmf <- TRUE else wmf <- FALSE
	getWinVal(winName="window",scope="L"); unpackList(PBSfish,scope="L");
	#print(plaster(strat)); print(plaster(sex)); print(plaster(ttype)); print(plaster(stype))

	plotname=paste(paste(c(spp,xy[2],plaster(areas,sep="+"),plaster(strat),plaster(sex),
		plaster(ttype),plaster(stype)),collapse="-"),sep="")
	if (wmf) win.metafile(width=8,height=8,filename=paste(plotname,".wmf",sep=""))
	else resetGraph()
	expandGraph(mfrow=c(1,1),mai=c(.6,.7,0.1,0.1),las=1)

	xlim <- unlist(XYopt[1,c("lim1","lim2")])
	ylim <- unlist(XYopt[2,c("lim1","lim2")])
	px <- is.element(xval,xlim[1]:xlim[2])
	py <- is.element(yval,ylim[1]:ylim[2])
	pa <- subset(pa,select=px); Na <- subset(Na,select=px)
	xval <- xval[px]; yval <- yval[py]; 
	nSID <- nSID[is.element(names(nSID),xlim[1]:xlim[2])]

	pin=par()$pin
	ad <- c(.02,0.01,ifelse(ltype==1,0.9/pin[2],.25/pin[2]),ifelse(ltype==1,.35/pin[2],0)) # extend range (x1,x2,y1,y2)
	dx <- max(1,diff(xlim)); xl <- xlim + c(-ad[1]*dx,ad[2]*dx)
	dy <- max(1,diff(ylim)); yl <- ylim + c(-ad[3]*dy,ad[4]*dy)
	zxt <- is.element(xval,seq(1950,2050,ifelse(length(xval)>20,5,ifelse(length(xval)>6,2,1))))
	zyt <- is.element(yval,seq(0,5000,ifelse(any(xy[2]==c("wt")),100,
		ifelse(any(xy[2]==c("len")),50,ifelse(any(xy[2]==c("age")),5,5)))))
	xlab <- paste(LETTERS[is.element(letters,substring(xy[1],1,1))],substring(xy[1],2),sep="")
	ylab <- paste(LETTERS[is.element(letters,substring(xy[2],1,1))],substring(xy[2],2),sep="")

	plotBubbles(pa,dnam=TRUE,smo=1/100,size=psize*pin[1],lwd=lwd,powr=powr,
		clrs=bcol,hide0=hide0,xlim=xl,ylim=yl,xlab="",ylab="",xaxt="n",yaxt="n")
	usr=par()$usr; dyu=diff(usr[3:4])
	if(showH) abline(h=yval[zyt],lty=3,col="grey30")
	tcol <- darken(bcol[1]); # text colour as darker RGB based on positive bubbles

   mtext(xlab,side=1,line=1.75,cex=1.5)
   mtext(ylab,side=2,line=2.25,cex=1.5,las=0)

   axis(1,at=xval,labels=FALSE,tck=-.005)
   axis(1,at=xval[zxt],mgp=c(0,.5,0),tck=-.02,adj=.5,cex=1)
   axis(2,at=yval,tck=.005,labels=FALSE)
   axis(2,at=yval[zyt],mgp=c(0,.5,0),tck=.02,adj=1,cex=1)

	mainlab <- paste(spn[spp],xy[2],ifelse(!is.null(strat),paste("\n...stratified ",
		ifelse(wted,"& weighted ",""),"by ",strat,sep=""),"not stratified"))
	i1=sordid(dat$sex,"sex");      i2=sordid(dat$gear,"gear")
	i3=sordid(dat$ttype,"ttype");  i4=sordid(dat$stype,"stype")
	i5=sordid(dat$major,"major");  i6=sordid(dat$srfa,"srfa")
	i7=sordid(dat$srfs,"srfs")
	infolab=""
	for (i in 1:7) {
		j=get(paste("i",i,sep=""))
		if (j=="") next
		else infolab=paste(infolab,j,ifelse(i==1,";   ","\n"),sep="") }
	infolab=substring(infolab,1,nchar(infolab)-1)
	Nlab <- apply(Na,2,sum); Nlab <- Nlab[Nlab>0 & !is.na(Nlab)];
	Npos <- as.numeric(names(Nlab)); Nfac=max(nchar(Nlab))
	Slab <- nSID; Slab <- Slab[Slab>0 & !is.na(Slab)];
	Spos <- as.numeric(names(Slab)); Sfac=max(nchar(Slab))
	switch (ltype,
		{addLabel(.03,.01,mainlab,cex=.8,adj=c(0,0),col=tcol);
		addLabel(.97,.01,infolab,cex=.7,adj=c(1,0),col="grey30");
		addLabel(.02,.99,"N",col=tcol,cex=1,adj=c(0,1));
		text(Npos,usr[4]-0.01*dy,Nlab,col=tcol,srt=90,adj=c(1,.5),cex=0.8)},
		{addLabel(.02,.02,"N",col="blue",cex=1,adj=c(0,0));
		text(Npos,usr[3]+0.01*dyu,Nlab,col=tcol,srt=270,adj=c(1,.5),cex=0.8)},
		{addLabel(.02,.02,"S",col=tcol,cex=1,adj=c(0,0));
		text(Spos,usr[3]+0.02*dyu,Slab,col=tcol,srt=270,adj=c(1,.5),cex=0.8)}
	)
	if (wmf) dev.off()
	packList(c("infolab","Nlab","Slab","Npos","Spos","plotname"),"PBSfish")
	invisible() }

#.plotProp.resetP-----------------------2010-10-20
.plotProp.resetP <- function() {
	resList <-
	structure(list(fnam = "pop.age", strat = "", wted = FALSE, spp = "POP", 
    Usex = c(TRUE, FALSE, FALSE, FALSE, FALSE), agg = FALSE, 
    bbonly = TRUE, Ugear = c(FALSE, FALSE, FALSE, FALSE), Uttype = c(FALSE, 
    FALSE, FALSE, FALSE, FALSE), Ustype = c(FALSE, FALSE, FALSE, 
    FALSE, FALSE), Umajor = c(FALSE, FALSE, FALSE, FALSE, FALSE, 
    FALSE, FALSE, FALSE), Usrfa = c(FALSE, FALSE, FALSE, FALSE, 
    FALSE, FALSE, FALSE), Usrfs = c(FALSE, FALSE, FALSE, FALSE
    ), psize = 0.03, powr = 0.5, lwd = 2, bcol = c("blue", "grey", 
    "coral"), showH = TRUE, hide0 = TRUE, ltype = 1, XYopt = structure(list(
        fld = c("year", "age"), lim1 = c(NA, 0), lim2 = c(NA_real_, 
        NA_real_), int = c(1, 1)), .Names = c("fld", "lim1", 
    "lim2", "int"), row.names = c("X", "Y"), class = "data.frame")), .Names = c("fnam", 
"strat", "wted", "spp", "Usex", "agg", "bbonly", "Ugear", "Uttype", 
"Ustype", "Umajor", "Usrfa", "Usrfs", "psize", "powr", "lwd", 
"bcol", "showH", "hide0", "ltype", "XYopt"))
	setWinVal(resList,winName="window")
	invisible() }

#.plotProp.resetT-----------------------2010-10-20
.plotProp.resetT <- function() {
	resList <- list(agg = FALSE, XYopt = structure(list(
        fld = structure(c(2L, 1L), .Label = c("age", "year"), class = "factor"), 
        lim1 = c(NA, 0), lim2 = c(NA_real_, NA_real_), int = c(1, 
        1)), .Names = c("fld", "lim1", "lim2", "int"), row.names = c("X", 
    "Y"), class = "data.frame"))
	setWinVal(resList,winName="window")
	invisible() }
#-----------------------------------------plotProp

#predictRER-----------------------------2011-06-14
# Discriminant function for the accurate classification
# of Rougheye Rockfish (RER) and Blackspotted Rockfish (BSR).
#
# Exploring 35 morphometric and 9 meristic characters,
# Orr and Hawkins (2008) provide a discriminant function 
# (using only 6 morphometrics L and 2 meristics N ) 
# that claims to correctly classify the two species 97.8%
# of the time. The discriminant score D predictions:
#
# When D < 0 then predicts Sebastes aleutianus (RER)
# When D > 0 then predicts Sebastes melanostictus (BSR)
# where
#  S    = standard fish length measured from tip of snout,
#  L[1] = length of dorsal-fin spine 1,
#  L[2] = snout length,
#  N[1] = number of gill rakers,
#  L[3] = length of gill rakers,
#  N[2] = number of dorsal-fin rays,
#  L[4] = length of pelvic-fin rays,
#  L[5] = length of soft-dorsal-fin base,
#  L[6] = preanal length.
#-----------------------------------------------RH
predictRER = function(S,L,N) {

	if (length(L)!=6) {
		mess = "Need 6 length measurements:\n\n\t1) dorsal fin spine 1\n\t2) snout\n\t3) gill rakers\n\t4) pelvic fin rays\n\t5) soft-dorsal-fin base\n\t6) preanal"
		showAlert(mess); stop(mess) }
	if (length(N)!=2) {
		mess = "Need 2 numbers:\n\n\t1) # gill rakers\n\t2) # dorsal-fin rays"
		showAlert(mess); stop(mess) }

	sL = L/S
	D  = 101.557*sL[1] + 52.453*sL[2] +  0.294* N[1] +
		   51.920*sL[3] +  0.564* N[2] - 38.604*sL[4] -
		   22.601*sL[5] - 10.203*sL[6] - 10.445
	return(D) }

#processBio-----------------------------2009-06-16
# Process results from 'gfb_bio.sql' query.
#-----------------------------------------------RH
processBio = function(dat=PBSdat,addsrfa=TRUE,addsrfs=TRUE,addpopa=TRUE,maxrows=5e4) {
	f=function(x){format(x,scientific=FALSE,big.mark=",")}
	atts=attributes(dat)[setdiff(names(attributes(dat)),c("names","row.names","class"))] # extra attributes to retain
	N=nrow(dat); nloop=ceiling(nrow(dat)/maxrows)
	DAT=NULL
	for (i in 1:nloop) {
		n0=(i-1)*maxrows+1; n1=min(i*maxrows,N)
		cat(paste("processing rows",f(n0),"to",f(n1),"of",f(N)),"\n"); flush.console()
		idat=dat[n0:n1,]
		idat$EID=n0:n1
		if (addsrfa)
			idat$srfa=calcSRFA(idat$major,idat$minor,idat$locality)
		if (addsrfs)
			idat$srfs=calcSRFA(idat$major,idat$minor,idat$locality,subarea=TRUE)
		if (addpopa){
			if (i==1) data(popa)
			datpopa=rep("",nrow(idat))
			events=idat[!is.na(idat$X) & !is.na(idat$Y),c("EID","X","Y")]
			if (nrow(events)>0) {
				events=as.EventData(events)
				locs=findPolys(events,popa,maxRows=maxrows)
				locs=zapDupes(locs,"EID")
				pdata=attributes(popa)$PolyData; #pdata$label=substring(pdata$label,5)
				pvec=pdata$label[locs$PID]; names(pvec)=locs$EID
				names(datpopa)=idat$EID
				datpopa[names(pvec)]=pvec }
			idat$popa=datpopa
		}
		aflds=c("EID","X","Y")
		idat=idat[,c(aflds,setdiff(names(idat),aflds))]
		DAT=rbind(DAT,idat)
	} # end nloop
	if (!any(is.na(DAT$X)) && !any(is.na(DAT$Y))) DAT=as.EventData(DAT)
	attributes(DAT)=c(attributes(DAT),atts)
	return(DAT) }
#---------------------------------------processBio

#reportCatchAge-------------------------2010-10-20
# Analyses and plots from catch-at-age report.
# Originals by Jon Schnute for Pacific ocean perch (pop).
#-----------------------------------------------RH
reportCatchAge <- function(prefix="pop", path=getwd(), hnam=NULL, ...) {

	prefix=as.character(substitute(prefix))
	assign("PBSfish",list(module="M02_Biology",func="reportCatchAge",plotname="Rplot",prefix=prefix),envir=.GlobalEnv)
	options(warn=-1)

	wpath <- .getWpath()
	if (is.null(path)) path <- .getApath()
	rtmp <- tempdir(); rtmp <- gsub("\\\\","/",rtmp)
	wnam <- paste(wpath,"reportCatchAgeWin.txt",sep="/")
	wtmp <- paste(rtmp,"reportCatchAgeWin.txt",sep="/")
	
	temp <- readLines(wnam)
	temp <- gsub("@wdf",wtmp,temp)
	temp <- gsub("@prefix",prefix,temp)
	temp <- gsub("@path",path,temp)
	if (!is.null(hnam) && is.character(hnam))
		temp <- gsub("#import=",paste("import=\"",hnam,"\"",sep=""),temp)
	writeLines(temp,con=wtmp)
	createWin(wtmp) 
	invisible() }

#.reportCatchAge.getrep-----------------2010-10-20
# Get the report file created by ADMB as directed by a TPL file
#-----------------------------------------------RH
.reportCatchAge.getrep <- function() {
	getWinVal(scope="L")
	report=paste(prefix,".rep",sep=""); repfile=paste(path,"/",report,sep="")
	if (!file.exists(convSlashes(repfile))) showError(repfile,"nofile")
	admRep <- readList(repfile); unpackList(admRep,scope="L")
	yr <- cdata$yr; age <- k:(k+nage-1); 
	Btot <- wgta %*% Nat; RkB <- wgta[1] * Nat[1,]
	catch <- cdata$catch; Ft <- -log(1 - catch/Btot);
	srng <- 1:(nyr-k);
	rbio <- wgta[1] * Nat[1,]; Rkprod <- rbio[k+srng]/SSB[srng];
	#nsurv=ncol(cdata)-3; sname=names(cdata)[4:ncol(cdata)]
	sname=setdiff(names(cdata),c("yr","catch","cf")); nsurv=length(sname)
	if (exists("q2",envir=sys.frame(sys.nframe()))) qq=c(qq,q2) # For backwards compatibility with 2-q model
	surveys=list()
	for (s in sname) {
		x=yr; y=cdata[,s]; z=y>0 & !is.na(y)
		if (substring(prefix,1,3)=="pop" && s=="B1") z = z & yr!=1995  # take out extra charter index from GBReed colum

		x=x[z]; y=y[z]
		if (substring(prefix,1,3)=="pop" && s=="B2") {
			x=c(x,1995); y=c(y,cdata[is.element(cdata$yr,1995),"B1"]) }
		surveys[[s]]=list(x=x,y=y) }
	poi <- function(x,y,...) {
		points(x,y,pch=15,col="darkolivegreen1",cex=1); points(x,y,pch=0,cex=1); };
	lin <- function(x,y,...) {
		lines(x,y,col="cornflowerblue",lwd=2); };
	ryrs <- c(1975.5,1988.5,1997.5) # regime shift years

	stuff=c("prefix","report",names(admRep),"yr","age","Btot","RkB","catch","Ft","Rkprod",
			"surveys","poi","lin","ryrs","qq")
	packList(stuff,"PBSfish") # to global PBSfish object
	invisible() }

#.reportCatchAge.checkssb---------------2010-10-20
# Check ADMB SSB calculation
#----------------------------------------------JTS
.reportCatchAge.checkssb <- function() {
	unpackList(PBSfish,scope="L");
	(mata %*% (wgtat*Nat)) -SSB; };

#.reportCatchAge.plotrep----------------2010-10-20
# Plot various components of the report file.
#-------------------------------------------JTS/RH
.reportCatchAge.plotrep=function(plotcodes, unique.only=TRUE) {
	choices=c("AA","AP","BE","CP","HS","PP","RN","RP","SB","SG","SM","WA")
	if (missing(plotcodes) || is.null(plotcodes) || length(plotcodes)==0 || all(plotcodes=="")) {
		showMessage(paste(c("The function '.reportCatchAge.plotrep' needs a vector of codes.\n",
		"Choose report items from:\n", "AA = Ages actual", "AP = Ages predicted", 
		"BE = Biomass estimates", "CP = Catch (sustainable) vs. productivity", 
		"HS = Harvest strategy", "PP = Probability of achieving productivity", 
		"RN = Recruitment numbers", "RP = Recruitment productivity", 
		"SB = Simulation: biomass at fixed catches", "SG = Simulation: growth rate vs. catch", 
		"SM = Selectivity and maturity vs. age", "WA = Weight vs. age"), 
		collapse="\n"), as.is=TRUE,col="dodgerblue",x=.05,adj=0); return() }
	if (is.null(PBSfish$report)) .reportCatchAge.getrep()

	# Plot bubbles for an age distribution
	AAfun = APfun = function(z,pow=0.5,siz=0.10){
		unpackList(PBSfish,scope="L");
		xlim <- range(yr);  xdiff <- diff(xlim); xlim <- xlim+0.02*c(-1,1)*xdiff;
		ylim <- range(age); ydiff <- diff(ylim); ylim <- ylim+0.05*c(-1,1)*ydiff;
		z[z==0 | is.na(z)] <- -.001;
		plotBubbles(z,powr=pow,size=siz,xval=yr,yval=age,xlab="Year",ylab="Age",
			xlim=xlim,ylim=ylim,clrs=c("grey30","white"),xaxt="n",yaxt="n")
		if (diff(xlim)<25) axis(1,at=seq(min(yr),max(yr),1),labels=TRUE)
		else axis(1,at=pretty(yr,n=10),labels=TRUE)
		ages=sort(unique(c(min(age),pretty(age,n=5),max(age))))
		axis(2,at=age[age%in%ages],labels=TRUE)
		amean <- age %*% z; 
		apos <- amean > 0; # exclude missing years
		packList("amean","PBSfish")
		lines(yr[apos],amean[apos],col="red",lwd=4)
		invisible() }

	# Plot biomass (total, mature, selected)
	BEfun <- function() { 
		unpackList(PBSfish,scope="L");
		mb <- max(Btot);
		plot(yr,Bt,type="l",ylim=c(0,mb),xlab="Year",ylab="Relative Biomass (t)",lwd=2); 
		lines(yr,SSB,lty=5,col="red",lwd=2); lines(yr,Btot,lty=3,col="blue",lwd=2); 
		for (i in 1:length(surveys)){
			unpackList(surveys[[i]])
			points(x,y/qq[i],pch=i,cex=1.25)}
		drawBars(yr,catch,width=1,col="cornflowerblue",lwd=2)
		invisible() }

	# Risk analysis: Ceq vs. RP
	# RPmin,RPmax=range of R; nRP=number of steps; C1,C2,nC,nT=choices for the simulation
	CPfun <- function() {
		unpackList(PBSfish,scope="L"); getWinVal(scope="L")
		rp <- seq(RPmin,RPmax,length=nRP); cp <- rep(0,nRP);
		for (i in 1:nRP) {
			simPop(RPsim=rp[i]);
			cp[i] <- PBSfish$Ceq; };
		packList(c("rp","cp"),"PBSfish")
		plot(rp,cp,xlab="Productivity (R/SSB)",ylab="Sustainable Catch (t)",xlim=c(0,RPmax),type="n");
		lin(rp,cp);  poi(rp,cp)
		invisible() }

	# Harvest strategy plot: F vs. B
	HSfun <- function() {
		unpackList(PBSfish,scope="L"); getWinVal(scope="L")
		nyr=length(yr); z=c(yr[1],ryrs,yr[nyr]); nreg=length(z)-1
		regimes=as.numeric(cut(yr,z,include.lowest=TRUE,labels=1:nreg))
		regs=sort(unique(regimes))
		clrs=c("red","green4","orange","blue","tan","purple")[regs]

		plot(Bt,Ft,xlim=c(0,max(Bt)),ylim=c(0,max(Ft)),
			xlab="Relative Biomass (t)",ylab="Fishing Mortality",type="n");
		lines(par()$usr[1:2],c(mmor,mmor),lty=1,col="grey",lwd=2); 
		if (HStrc)
			arrows(Bt[1:(nyr-1)],Ft[1:(nyr-1)],Bt[2:nyr],Ft[2:nyr],length=.075,col="darkgrey")
		for (i in regs) {
			zi=is.element(regimes,i)
			points(Bt[zi],Ft[zi],pch=i,col=clrs[i],cex=1.5) }
		points(Bt[nyr],Ft[nyr],pch=22,bg="whitesmoke",cex=1.5) # Final year
		Bmn=sapply(split(Bt,regimes),mean,na.rm=TRUE)
		Fmn=sapply(split(Ft,regimes),mean,na.rm=TRUE)
		if (HSreg) {
			lines(Bmn,Fmn,col="black",lwd=2);
			for (i in regs)
				points(Bmn[i],Fmn[i],pch=i,cex=switch(i,4,3,2.5,3),col=clrs[i],lwd=4) }
		stuff=c("regimes","Bmn","Fmn"); packList(stuff,"PBSfish")
		box(); invisible() }

	# Productivity probability
	PPfun <- function() {
		unpackList(PBSfish,scope="L"); getWinVal(scope="L")
		srng <- 1:(nyr-k);
		rbio <- wgta[1] * Nat[1,]; rprod <- rbio[k+srng]/SSB[srng];
		rok <- rprod[rprod<=RPmax]; rn <- length(rok);
		pp <- 1 - (0:(rn-1))/max(srng); rps <- sort(rok);
		packList(c("rbio","rprod","rps","pp"),"PBSfish")
		plot(rps,pp,xlim=c(0,RPmax),ylim=c(0,1),xlab="Productivity (R/SSB)",ylab="Probability",typ="n");
		lin(rps,pp);  poi(rps,pp)
		invisible() }

	# Recruitment biomass at ages k and kplus
	RNfun <- function() { 
		unpackList(PBSfish,scope="L"); getWinVal(scope="L")
		Rk2B <- wgta[1+Roff]*Nat[1+Roff,]
		rmax <- max(RkB,Rk2B);
		plot(yr,RkB,type="n",xlim=range(yr),ylim=c(0,rmax),xlab="Year",ylab="Recruitment (t)")
		for (i in 1:length(ryrs)) {
			ii=if(i%%2) 1 else 2
			lines(c(ryrs[i]+k,ryrs[i]+k),par()$usr[3:4],lty=3,lwd=2,
			col=switch(ii,"green4","red")) }
		lines(yr,Rk2B,col="cornflowerblue",lty=5,lwd=2)
		lines(yr,RkB,col="grey40",lty=1,lwd=2)
		packList("Rk2B","PBSfish")
		invisible() }

	# Recruitment productivity
	RPfun <- function() { 
		unpackList(PBSfish,scope="L");
		srng <- 1:(nyr-k);
		#rbio <- wgta[k-6] * Nat[k-6,]; rprod <- rbio[k+srng]/SSB[srng];
		rbio <- wgta[1] * Nat[1,]; rprod <- rbio[k+srng]/SSB[srng];
		rmx <- max(rprod);
		plot(yr[srng],rprod,xlim=range(yr),xlab="Year",ylab="Productivity (R/SSB)",type="n"); 
		for (i in 1:length(ryrs)) {
			ii=if(i%%2) 1 else 2
			lines(c(ryrs[i],ryrs[i]),par()$usr[3:4],lty=3,lwd=2,
			col=switch(ii,"green4","red")) }
		lines(yr[srng],rprod,lwd=2);  poi(yr[srng],rprod)
		invisible() }

	# Simulate biomass at fixed catch
	SBfun <- function() {
		simPop()
		unpackList(PBSfish,scope="L"); getWinVal(scope="L")
		xlim <- range(pyr);  xdiff <- diff(xlim); xlim <- xlim+0.02*c(-1,1)*xdiff;
		ylim <- range(Cval); ydiff <- diff(ylim); ylim <- ylim+0.05*c(-1,1)*ydiff;
		plotBubbles(SB,xval=pyr,yval=Cval,xlim=xlim,ylim=ylim,
			xlab="Year",ylab="Catch (t)",clrs=c("grey30","white"))
		if (Ceq>0) abline(h=Ceq,col="cornflowerblue",lwd=2)
		invisible() }
	
	# Simulate biomass at fixed catch
	SGfun <- function() {
		simPop()
		unpackList(PBSfish,scope="L"); getWinVal(scope="L")
		plot(Cval,(SB[,nT]/SB[,1])^(1/nT),type="n",xlab="Catch (t)",ylab="Growth Rate");
		lin(Cval,(SB[,nT]/SB[,1])^(1/nT));
		if (Ceq>0) { lines(c(par()$usr[1],Ceq,Ceq),c(1,1,par()$usr[3]),lty=3,col="blue"); };
		invisible() }

	# Plot selectivity beta[a] and maturity[a]
	SMfun <- function() {
		unpackList(PBSfish,scope="L");
		plot(age,bta,ylim=c(0,1),xlab="Age",ylab="Selectivity (pts), Maturity (line)",type="n");
		lines(age,mata,col="red",lwd=2); 
		for (i in 1:4) lines(c(5*(1+i),5*(1+i)),c(0,bta[5*i-1]),lty=3); 
		poi(age,bta)
		invisible() }

	# Plot weight[a]
	WAfun <- function() { 
		unpackList(PBSfish,scope="L");
		y <- wgtat[,nyr]; ym <- max(y);
		plot( age, y, xlab="Age", ylab="Weight (kg)", ylim=c(0,ym) );
		lin(age,y); poi(age,y)
		invisible() }

	# Simulate populations across a range of catches
	# C1,C2=range of catches   nC=number of catch values
	# nT=number of time steps  RP=constant value of RecProd
	# Output: SB=matrix[nC,nT] of stock biomasses
	simPop <- function(RPsim=NULL) {
		unpackList(PBSfish,scope="L"); getWinVal(scope="L")
		if (!is.null(RPsim)) RP=RPsim
		Cval <- seq(C1,C2,length=nC); pyr <- yr[length(yr)] + (1:nT);
		SB <- matrix(0,nrow=nC,ncol=nT);
		Nvec0 <- Nat[,nyr];
		for (i in 1:nC) {
			Nvec <- Nvec0;
			Cbio <- Cval[i];                          # catch biomass
			stk <- (mata * wgta) %*% Nvec;            # stock biomass
			SB[i,1] <- stk;
			for (tt in 2:nT) {
				u <- bta*Nvec/sum(bta*Nvec);           # proportions in catch
				w <- u %*% wgta;                       # mean weight in catch
				Cnum <- Cbio/w;                        # catch numbers
				Nvec1 <- pmax( exp(-mmor)*(Nvec-u*Cnum), 0 );
				Nvec1[nage] <- Nvec1[nage] + Nvec1[nage-1];
				Nvec[2:(nage-1)] <- Nvec1[1:(nage-2)];
				Nvec[1] <- RP*stk; 
				stk <- (mata * wgta) %*% Nvec;         # spawning stock biomass
				SB[i,tt] <- stk;
			}; };
		grate <- (SB[,nT]/SB[,1])^(1/nT);            # growth rate
		gi0 <- (grate < 1); gi1 <- (grate > 1);
		if (any(gi0==TRUE)) i0 <- min((1:nC)[gi0]) else i0 <- nC; 
		if (any(gi1==TRUE)) i1 <- max((1:nC)[gi1]) else i1 <- 1;
		Ceq <- 0;
		if ( (i0>1) & (i1<=nC) ) 
			Ceq <- approx(grate,Cval,xout=1,rule=2,ties="ordered")$y 
		packList(c("pyr","Ceq","Cval","SB","grate","nT"),"PBSfish")
		invisible() }

	# Main body of .reportCatchAge.plotrep()
	plotcodes=plotcodes[is.element(plotcodes,choices)]
	if (unique.only) plotcodes=unique(plotcodes) # order is retained
	N=length(plotcodes); rc=PBSmodelling:::.findSquare(N); pnum=0; cexN=3/sqrt(N)
	figpars=list(mfrow=rc,mar=c(4.5,4,0.5,1),oma=c(0,0,0,0),mgp=c(2.5,.5,0),las=1,tcl=-.3)
	unpackList(PBSfish,scope="L")
	unpackList(figpars); resetGraph()
	expandGraph(mfrow=mfrow, mar=mar,oma=oma,mgp=mgp,las=las,tcl=tcl)
	for (i in plotcodes) {
		pnum = pnum + 1
		if (i=="AA") arg="pat" else if (i=="AP") arg="uat" else arg=""
		ifun=paste(i,"fun",sep="")
		if (exists(ifun,envir=sys.frame(sys.nframe())))
			eval(parse(text=paste(ifun,"(",arg,")",sep="")))
		else { 
			plot(0,0,type="n",xaxt="n",yaxt="n",xlab="",ylab="")
			addLabel(.5,.5,paste("'",i,"' not available",sep=""),cex=cexN,col="red") }
		if (N>1) addLabel(.95,.95,LETTERS[pnum],cex=cexN,adj=1)
	}
	invisible() }
#-----------------------------------reportCatchAge

#requestAges----------------------------2012-11-15
# Determine which otoliths to sample for ageing requests.
# Note: only have to use sql=TRUE once for each species 
# using any year before querying a group of years.
# Note: ageing methdology is not a sensible selection criterion because the fish selected have not been aged.
#-----------------------------------------------RH
requestAges=function(strSpp, nage=500, year=2011, 
     areas=list(major=3:9, minor=NULL), ttype=c(1,4),
     sex=1:2, nfld = "nallo", sql=TRUE, 
     spath=.getSpath(), uid=Sys.info()["user"], pwd=uid, ...) {

	on.exit(gc())
	assign("PBSfish",list(module="M02_Biology",call=match.call()),envir=.GlobalEnv)

	#Subfunctions -----------------------
	adjustN = function(a,b){           # a=available , b=desired
		if (round(sum(b),5) > round(sum(a),5)) {
			showMessage(paste("There are only",sum(round(a,0)),"otoliths available.\n",
				"All were selected."),as.is=TRUE)
			return(round(a)) }
		za = b>a                        # restricted to available
		if (any(za)) {
			aN = rep(0,length(a))        # adjusted N
			aN[za] = a[za]
			aN[!za] = b[!za]
			pb = b[!za]/sum(b[!za])      # proportion of non-restricted desired
			sN = sum(b[za]-a[za])        # surplus desired
			aN[!za] = aN[!za] + pb*sN    # allocate surplus
			adjustN(a,aN)                # re-iterate
		}
		else return(round(b)) }

	moveCat=function(C,S){
		if (all(S)) return(C) # all periods sampled, no need to move catch
		n=length(C); x=1:n; y=rep(0,n)
		y[!S]=.05
		for (i in x) {
			if (S[i]) next
			z   = (x-x[i])^2 + (y-y[i])^2
			zz  = z==sort(z[S])[1]
			zzz = zz/sum(zz)
			C   = C + C[i]*zzz
			C[i]= 0 }
		return(C) }

	catnip = function(...) {cat(... ,sep="")}
	#------------------------subfunctions

	if (sql) {
		expr=paste(c("getData(\"gfb_age_request.sql\"",
			",dbName=\"GFBioSQL\",strSpp=\"",strSpp,"\",path=\"",spath,"\")"),collapse="")
		expr=paste(c(expr,"; Sdat=PBSdat"),collapse="")
		expr=paste(c(expr,"; save(\"Sdat\",file=\"Sdat",strSpp,".rda\")"),collapse="")      # Sample data (binary)
		expr=paste(c(expr,"; write.csv(Sdat,file=\"Sdat",strSpp,".csv\")"),collapse="")     # Sample data (ascii)

		expr=paste(c(expr,"; getData(\"gfb_pht_catch.sql\",\"",
			"GFBioSQL\",strSpp=\"",strSpp,"\",path=\"",spath,"\")"),collapse="")
		expr=paste(c(expr,"; phtcat=PBSdat"),collapse="")

		expr=paste(c(expr,"; getData(\"gfb_fos_catch.sql\",\"",
			"GFBioSQL\",strSpp=\"",strSpp,"\",path=\"",spath,"\")"),collapse="")
		expr=paste(c(expr,"; foscat=PBSdat"),collapse="")
		expr=paste(c(expr,"; Ccat=rbind(phtcat,foscat[,names(phtcat)])"),collapse="")
		expr=paste(c(expr,"; save(\"Ccat\",file=\"Ccat",strSpp,".rda\")"),collapse="")      # Commercial catch (binary)
		expr=paste(c(expr,"; write.csv(Ccat,file=\"Ccat",strSpp,".csv\")"),collapse="")     # Commercial catch (ascii)

		expr=paste(c(expr,"; getData(\"gfb_gfb_catch.sql\",\"",
			"GFBioSQL\",strSpp=\"",strSpp,"\",path=\"",spath,"\")"),collapse="")
		expr=paste(c(expr,"; Scat=PBSdat"),collapse="")
		expr=paste(c(expr,"; save(\"Scat\",file=\"Scat",strSpp,".rda\")"),collapse="")      # Survey catch (binary)
		expr=paste(c(expr,"; write.csv(Scat,file=\"Scat",strSpp,".csv\")"),collapse="")     # Survey catch (ascii)
		eval(parse(text=expr)) } 
	else { 
		expr=paste(c("load(\"Sdat",strSpp,".rda\"); load(\"Ccat",strSpp,".rda\"); ",
			"load(\"Scat",strSpp,".rda\")"),collapse="")
		eval(parse(text=expr)) }
	
	if (nrow(Sdat)==0 || nrow(Ccat)==0) showError("Not enough data")
	samp=Sdat
	if (all(sex==1)){
		samp$NOTO=samp$Moto; samp$NBBA=samp$Mbba; samp$NAGE=samp$Mage}  # males
	else if (all(sex==2)){
		samp$NOTO=samp$Foto; samp$NBBA=samp$Fbba; samp$NAGE=samp$Fage}  # females
	else if (all(sex==c(1,2))) {
		samp$NOTO=samp$Moto+samp$Foto; samp$NBBA=samp$Mbba+samp$Fbba; samp$NAGE=samp$Mage+samp$Fage } # males and females only
	else {
		samp$NOTO=samp$Noto; samp$NBBA=samp$Nbba; samp$NAGE=samp$Nage; sex=0:3}  # all available
	samp$year=convFY(samp$tdate,1)
	nfree = round(samp$NOTO-samp$NAGE)
	if (!is.null(list(...)$nfree)) samp <- samp[nfree>=list(...)$nfree & !is.na(nfree),]
	if (is.null(ttype)) showError("Choose a trip type")
	else if (sum(is.element(ttype,2:3))==0 & sum(is.element(ttype,c(1,4:14)))>0) type="C" # commercial
	else if (sum(is.element(ttype,2:3))>0 & sum(is.element(ttype,c(1,4:14)))==0) type="S" # research/survey
	else showError("Choose ttypes out of:\n   {2,3} (research/survey) OR\n   {1,4:14} (commercial)")

	if (type=="C") catch = Ccat
	else if (type=="S") catch = Scat
	else showError ("No catch data")

	z = catch$date < as.POSIXct("1996-01-01") | catch$date > Sys.time()
	catch = catch[!z,]
	catch$year=convFY(catch$date,1)
	if (type=="C") {
		samp$tid = rep(0,nrow(samp)); catch$tid = rep(0,nrow(catch))
		zfos = samp$tdate > as.POSIXct("2007-03-31") #& samp$TID_fos > 0
		samp$tid[zfos]   = samp$TID_fos[zfos]
		samp$tid[!zfos]  = samp$TID_gfb[!zfos]
		zfos = catch$date > as.POSIXct("2007-03-31")
		catch$tid[zfos]   = catch$TID_fos[zfos]
		catch$tid[!zfos]  = catch$TID_gfb[!zfos]
	}
	else {
		samp$tid  = paste(samp$TID_gfb,samp$FEID,sep=".")
		catch$tid = paste(catch$TID,catch$FEID,sep=".")
	}
#browser();return()
	spooler(areas,"area",samp) # creates a column called 'area' and populates based on argument 'areas'.
	spooler(areas,"area",catch)
	area=sort(unique(samp$area))
	unpackList(list(...))
	for (i in intersect(c("year","area","ttype","TID_gfb","TID_fos"),ls())) {
		eval(parse(text=paste("samp=biteData(samp,",i,")",sep="")))
		if (i!="ttype") eval(parse(text=paste("catch=biteData(catch,",i,")",sep="")))
	}
	if (nrow(samp)==0)  showError("No records left in 'samp'. Ease your restrictions")
	if (nrow(catch)==0) showError("No records left in 'catch'. Ease your restrictions")

	samp=samp[order(samp[[ifelse(type=="C","tdate","FEID")]]),]
	z0=is.element(samp$tid,0)
	if (any(z0)) samp$tid[z0] = 1:sum(z0)

	catch=catch[order(catch$date),]
	z0=is.element(catch$tid,0)
	if (any(z0)) catch$tid[z0] = catch$hail[z0]

	if (type=="C") {
		Clev = convYP(catch$date)                             # all periods in commercial catch
		clev = names(Clev)
		Slev = convYP(samp$tdate)                             # periods in sample data
		slev= names(Slev)
	}
	if (type=="S") {
		cid=catch$tid
		sid=samp$tid
#browser();return()
		# 'gfb_age_request.sql" now gathers Grouping Code (GC)
		#group=catch$GC; names(group)=cid
		#samp$GC=group[sid]; samp=samp[!is.na(samp$GC),] #get rid of unidentified groups (strata)
		Clev  = paste(catch$year,pad0(catch$GC,3),sep="-") # all groups in survey catch
		Slev  = paste(samp$year,pad0(samp$GC,3),sep="-")   # groups in sample data
		clev=names(Clev)=Clev; slev=names(Slev)=Slev
	}
	samp$lev = slev
	ulev = sort(unique(samp$lev))                            # unique periods in sample data
	C=sapply(split(catch$catKg,clev),sum)/ifelse(type=="C",1000.,1.) # total catch at each level
	S=is.element(names(C),ulev)

	CC   = moveCat(C,S)
#browser();return()
	if (round(sum(C),5)!=round(sum(CC),5)) showError("Catch shuffling amongst periods not successful")
	ccat = catch$catKg; names(ccat) = catch$tid         # trip catch of species
	zper = is.element(clev,ulev)                        # index of unique periods
	cper = Clev[zper]                                   # periods in comm.catch in common with those from samples
	ccat = ccat[zper]                                   # comm.catch relevant to sample periods
	qcat = split(ccat,names(cper))
	#qC   = CC[ulev]
	qC   = CC[intersect(names(CC),ulev)]
	pC   = qC / sum(qC)                                 # proportion of total catch in each period
	nC   = pC * nage                                    # number of otoliths to age per period, given a fixed budget
	samp[["Tcat"]] = qC[samp$lev]                       # populate the data frame with period/strata catches
	samp[["Pcat"]] = pC[samp$lev]                       # populate the data frame with period/strata catches
	samp[["Ncat"]] = nC[samp$lev]                       # populate the data frame with period/strata catches

	samp$ncat=samp$pcat=samp$tcat=rep(0,nrow(samp))     # prepare blank columns in data frame
	for (i in names(qC)) {                              # loop through periods (quarters)
		zc = is.element(names(qcat[[i]]),samp$tid)       # index the trips from the comm.catch in each period
		if (!any(zc)) next
		tcat = qcat[[i]][zc]                             # can contain multiple catches per trip due to areas
#if (i=="2005-04") {browser();return()}
		tcat = sapply(split(tcat,names(tcat)),sum)       # rollup area catches
		pcat = tcat/sum(tcat)                            # proportion of period catch taken by each trip
		ncat = pcat*nC[i]                                # allocate fish to age based on proportion of trip catch in period
		zs   = is.element(samp$tid,names(tcat))          # index the trips from the sample data in each period
		zss  = as.character(samp$tid[zs])                # tid can have more than one sample
		samp[["tcat"]][zs] = tcat[zss]                   # populate the data frame with trip catches
		samp[["pcat"]][zs] = pcat[zss]                   # populate the data frame with trip catch proportions
		samp[["ncat"]][zs] = ncat[zss]                   # populate the data frame with number of specimens to age
	}
	packList(c("Sdat","catch","C"),"PBSfish")
	samp$nwant = round(samp$ncat)                                # No. otoliths wanted by the selection algorithm
	samp$ndone = samp$NBBA                                       # No. otoliths broken & burnt
	samp$nfree = round(samp$NOTO-samp$NAGE)                      # No. of free/available otoliths not yet processed
	samp$ncalc = pmin(pmax(0,samp$nwant-samp$ndone),samp$nfree)  # No. of otoliths calculated to satisfy Nwant given constraint of Nfree
#browser();return()
	nardwuar = samp$ncalc > 0 & !is.na(samp$ncalc)
	samp$nallo = rep(0,nrow(samp))
	samp$nallo[nardwuar] = adjustN(a=samp$nfree[nardwuar],b=samp$nwant[nardwuar])  # No. of otoliths allocated to satisfy user's initial request, given constraint of Nfree
	narduse = samp[,nfld] > 0 & !is.na(samp[,nfld])
	sampuse = samp[narduse,]
	### End sample calculations ###

	yearmess = if (length(year)>3) paste(min(year),"-",max(year),sep="") else paste(year,collapse="+")
	describe=paste("-",type,"(",yearmess,")-area(",area,")-sex(",paste(sex,collapse="+"),")-N",round(sum(samp[,nfld])),sep="")
	attr(samp,"Q") = cbind(qC,pC,nC)
	attr(samp,"call") = deparse(match.call())
	packList(c("samp","describe"),"PBSfish")
	save("samp",file=paste("Sdat",strSpp,describe,".rda",sep=""))
	write.csv(samp,  paste("Sdat",strSpp,describe,".csv",sep=""))
#browser();return()

	tid=unique(sampuse[["tid"]])
	sid=unique(sampuse[["SID"]])
	# Get list of available otoliths.
	expr=paste("SELECT B5.SAMPLE_ID AS SID, B5.SPECIMEN_SERIAL_NUMBER AS SN FROM B05_SPECIMEN B5 WHERE B5.SAMPLE_ID IN (",
		paste(sid,collapse=","),") AND B5.AGEING_METHOD_CODE IS NULL AND B5.SPECIMEN_SEX_CODE IN (", paste(sex,collapse=","),")",sep="")
	getData(expr,"GFBioSQL",strSpp=strSpp,type="SQLX")
	Opool = split(PBSdat$SN,PBSdat$SID)                    # Pool of available otoliths
	Npool = Opool[as.character(sampuse$SID)]         # Pool relevant to the n field
	Nsamp = sampuse[,nfld]; names(Nsamp)=sid; names(sid)=tid  # Number of otoliths to sample from the pool
#browser();return()
	Osamp = sapply(sid,function(x,O,N){                    # Otoliths sampled randomly from pool
		xx=as.character(x); o=O[[xx]]; n=N[xx]
		if (n==0) NA else sample(o,min(n,length(o)),replace=FALSE) }, 
		O=Npool, N=Nsamp, simplify=FALSE)
	packList(c("Opool","Nsamp","Osamp"),"PBSfish")

	fnam = paste("oto",strSpp,describe,".csv",sep="")
	data(species); data(pmfc)
	catnip(paste("Otolith Samples for", species[strSpp,]["name"],"(", species[strSpp,]["latin"],")"),"\n\n",file=fnam)
	for (i in tid) {
		ii=as.character(i)
		otos=Osamp[[ii]]
		if ( all(is.na(otos))) next
		x=samp[is.element(samp$tid,i),]
		unpackList(x); ntray=0; ser1=NULL
		for (j in 1:length(firstSerial)) {
			sers = firstSerial[j]:lastSerial[j]
			ser1 = c(ser1, sers[seq(1,length(sers),100)]) } # first serials including n samples > 100 (tray)
		ntray=length(ser1)
		tray=array("",dim=c(5,20,ntray),dimnames=list(LETTERS[1:5],1:20,ser1))
		for (j in ser1) {
			serT = matrix(seq(j,j+99,1),nrow=5,ncol=20,byrow=TRUE)
			zoto = is.element(serT,otos)
			if (any(zoto))  tray[,,as.character(j)][zoto]=serT[zoto] }
		TRAY = apply(tray,1:2,function(x){paste(x[x!=""],collapse=" & ")})
		catnip("Vessel,",vessel[1],",\n",file=fnam,append=TRUE)
		catnip("Trip date,",format(tdate[1],format="%d-%b-%Y"),",",file=fnam,append=TRUE)
		catnip("Otoliths","\n",file=fnam,append=TRUE)
		catnip("Sample date,",format(sdate[1],"%d-%b-%Y"),",",file=fnam,append=TRUE)
		catnip("<",length(otos),">","\n",file=fnam,append=TRUE)
		#if (type=="C") catnip("Hail,",hail[1],",",file=fnam,append=TRUE)
		#else           catnip("FEID,",FEID[1],",",file=fnam,append=TRUE)
		catnip("Sample ID,",SID[1],",",file=fnam,append=TRUE)
		catnip("Tray,",paste(1:20,collapse=","),"\n",file=fnam,append=TRUE)
		catnip("Set,",paste(unique(set),collapse="+"),",",file=fnam,append=TRUE)
		catnip("A,",paste(TRAY[1,],collapse=","),"\n",file=fnam,append=TRUE)
		#catnip("PMFC major,",paste(unique(major),collapse="+"),",",file=fnam,append=TRUE)
		#catnip("PMFC areas,",paste(paste(unique(major),collapse="+"),paste(unique(minor),collapse="+"),sep=" - "),",",file=fnam,append=TRUE)
		catnip("PMFC,",pmfc[as.character(major[1]),"name"],",",file=fnam,append=TRUE)
		catnip("B,",paste(TRAY[2,],collapse=","),"\n",file=fnam,append=TRUE)
		#catnip("PMFC minor,",paste(unique(minor),collapse="+"),",",file=fnam,append=TRUE)
		catnip("Storage box,",storageID[1],",",file=fnam,append=TRUE)
		catnip("C,",paste(TRAY[3,],collapse=","),"\n",file=fnam,append=TRUE)
		catnip("Prefix,",prefix[1],",",file=fnam,append=TRUE)
		catnip("D,",paste(TRAY[4,],collapse=","),"\n",file=fnam,append=TRUE)
		catnip("First serial,",paste(firstSerial,collapse=" | "),",",file=fnam,append=TRUE)
		catnip("E,",paste(TRAY[5,],collapse=","),"\n",file=fnam,append=TRUE)
		catnip("Last serial,",paste(lastSerial,collapse=" | "),"\n\n",file=fnam,append=TRUE)
#if (storageID=="17Q+17R") {browser();return()}
	}
	invisible(samp) }
#--------------------------------------requestAges

#simBSR---------------------------------2011-06-14
# Simulate Blackspotted Rockfish biological data.
#-----------------------------------------------RH
simBSR = function(Nfish) {
	SL  = runif(Nfish,95.5,539)   # Standard length (mm)
	L1 = rnorm(Nfish,7.8,0.7)     # Length of dorsal-fin spine 1 (%SL)
	L2 = rnorm(Nfish,8.0,0.6)     # Snout length (%SL)
	L3 = rnorm(Nfish,5.6,0.6)     # Length of gill rakers (%SL)
	L4 = rnorm(Nfish,21.4,1.2)    # Length of pelvic-fin rays (%SL)
	L5 = rnorm(Nfish,21.4,1.5)    # Length of soft-dorsal-fin base (%SL)
	L6 = rnorm(Nfish,70.2,2.6)    # Preanal length (%SL)
	N1 = rnorm(Nfish,33.0,1.2)    # Number of gill rakers
	N2 = rnorm(Nfish,13.7,0.5)    # Number of dorsal-fin rays

	S = cbind(SL)
	L = cbind(L1,L2,L3,L4,L5,L6); L = sweep(L,1,SL,"*")/100
	N = cbind(N1,N2)
	SLN = cbind(S,L,N); dimnames(SLN)=list(1:Nfish,c("S","L1","L2","L3","L4","L5","L6","N1","N2"))
	attr(SLN,"spp") = "BSR"
	return(SLN) }

#simRER---------------------------------2011-06-14
# Simulate Rougheye Rockfish biological data.
#-----------------------------------------------RH
simRER = function(Nfish) {
	SL  = runif(Nfish,63.4,555.2) # Standard length (mm)
	L1 = rnorm(Nfish,5.8,0.6)     # Length of dorsal-fin spine 1 (%SL)
	L2 = rnorm(Nfish,7.5,0.7)     # Snout length (%SL)
	L3 = rnorm(Nfish,4.9,0.6)     # Length of gill rakers (%SL)
	L4 = rnorm(Nfish,22.1,1.1)    # Length of pelvic-fin rays (%SL)
	L5 = rnorm(Nfish,22.8,1.2)    # Length of soft-dorsal-fin base (%SL)
	L6 = rnorm(Nfish,71.8,2.3)    # Preanal length (%SL)
	N1 = rnorm(Nfish,31.2,1.0)    # Number of gill rakers
	N2 = rnorm(Nfish,13.5,0.5)    # Number of dorsal-fin rays

	S = cbind(SL)
	L = cbind(L1,L2,L3,L4,L5,L6); L = sweep(L,1,SL,"*")/100
	N = cbind(N1,N2)
	SLN = cbind(S,L,N); dimnames(SLN)=list(1:Nfish,c("S","L1","L2","L3","L4","L5","L6","N1","N2"))
	attr(SLN,"spp") = "RER"
	return(SLN) }

#sumBioTabs-----------------------------2009-11-25
# Summarize frequency occurrence of biological samples
# and specimens and send output to a data table.
#-----------------------------------------------RH
sumBioTabs=function(dat, fnam="sumBioTab.csv", samps=TRUE, specs=TRUE,
     facs=list(c("year","major"), c("year","ttype"), c("year","stype"),
     c("year","ameth") )){
	if(samps) require(reshape)
	cat("Summary Tables\n\n",file=fnam)
	for (f in facs) {
		cat(paste(f,collapse=" vs "),": ",file=fnam,append=TRUE)
		if (samps) {
			molten=melt.data.frame(dat,f,"SID")
			sa=cast(molten,paste(f,collapse="~"),function(x){length(unique(x))}) 
			cat(paste("Samples",ifelse(specs," & ","\n"),sep=""),file=fnam,append=TRUE) }
		if (specs) {
			sp=table(dat[[f[1]]],dat[[f[2]]])
			sp=matrix(sp,nrow=nrow(sp),dimnames=dimnames(sp))
			cat("Specimens\n",file=fnam,append=TRUE) }
		if (samps) out=data.frame(A=sa)
		if (samps & specs) out=data.frame(out,C.=rep("",nrow(sa)))
		if (specs & !samps) { 
			out=rownames(sp)
			eval(parse(text=paste("out=as.",class(dat[[f[1]]]),"(out); out=data.frame(",f[1],"=out)",sep=""))) }
		if (specs) out=data.frame(out,B=sp)
		header=gsub("[ABC]\\.","",names(out))
		cat(paste(header,collapse=","),"\n",file=fnam,append=TRUE)
		write.table(out,fnam,sep=",",row.names=FALSE,col.names=FALSE,append=TRUE)
		cat("\n",file=fnam,append=TRUE)
	} }
#---------------------------------------sumBioTabs

#weightBio------------------------------2012-09-18
# Weight age|length frequencies|proportions by catch|density.
#   adat = age123 from query 'gfb_bio.sql'    -- e.g., getData("gfb_bio.sql","GFBioSQL",strSpp="439",path=.getSpath()); bio439=processBio()
#   cdat = cat123.wB from function 'getCatch' -- e.g., getCatch("439",pwd="myGFSHpwd",sql=TRUE)
#-----------------------------------------------RH
weightBio = function(adat, cdat, sunit="TID", sweight="catch", 
     ttype=NULL, stype=c(0,1,2,5:8), ameth=3, sex=1:2, major=NULL, 
     wSP=c(TRUE,TRUE), wN=TRUE, plus=60, Nmin=0, Amin=NULL, 
     ctype="C", per=90, SSID=32, tabs=TRUE, 
     plot=TRUE, ptype="bubb", size=0.15, powr=0.5, zfld="wp", 
     clrs=list(c("blue","cyan"),c("green4","chartreuse")),
     cohorts=NULL, #list(x=c(1962,1970,1977,1989,1990,1992,1999),y=rep(0,7)),
     #regimes=list(1926:1929,1939:1946,1977:1978,1980:1981,1983:1984,1986:1988,1991:1992,1995:2006), #ALPI
     regimes=list(1900:1908,1912:1915,1923:1929,1934:1943,1957:1960,1976:1988,1992:1998,2002:2006),  #PDO
     #regimes=list(1912:1915,1923:1929,1931,1934:1943,1947,1957:1958,1960,1976:1988,1992:1993,1995:1998,2002:2006,2010), #PDO
     layout="portrait", wmf=FALSE, pix=FALSE, eps=FALSE, longside=10, ...) {

	expr = paste("getFile(",substitute(adat),",",substitute(cdat),",try.all.frames=TRUE,scope=\"G\")",sep="")
	eval(parse(text=expr))
	strSpp=attributes(adat)$spp; if(is.null(strSpp)) strSpp="000"
	assign("PBSfish",list(module="M02_Biology",call=match.call(),args=args(weightBio),spp=strSpp),envir=.GlobalEnv)
	sysyr=as.numeric(substring(Sys.time(),1,4)) # maximum possible year
	if (is.null(major)) {
		adat$major[is.null(adat$major)] = 0
		cdat$major[is.null(cdat$major)] = 0
		major = sort(unique(adat$major)) }
	if (is.null(ttype)) {
		if (ctype=="C")      ttype = c(1,4) # commercial
		else if (ctype=="S") ttype = c(2,3) # research/survey
		else                 ttype = 1:14 }

	# Age data
	ages = adat
	flds=c("ttype","stype","ameth","sex","major"); #if (ctype=="S") flds=c(flds,"SVID")
	for (i in flds) {
		expr=paste("ages=biteData(ages,",i,")",sep=""); eval(parse(text=expr)) }
	if (nrow(ages)==0) showError(paste("No data for '",paste(flds,collapse=', '),"' chosen",sep=""))
	ages$age[ages$age>=plus & !is.na(ages$age)] = plus
	# if weighting by [sweight], you need a positive [sweight] :
	if (wSP[1]) ages = ages[ages[,sweight]>0 & !is.na(ages[,sweight]),]

	# Restratify the survey age data (because there are numerous restratification schemes not reflected in B21)
	if (ctype=="S"){
		cdat = cdat[is.element(cdat$SSID,SSID),]
		feid = cdat$FEID
		strata = cdat$GC; names(strata) = feid      # take stratification scheme from survey catch data
		SVID   = cdat$SVID;  names(SVID)   = feid
		ages   = ages[is.element(ages$FEID,feid),]  # get ages associated with the survey series
		if (nrow(ages)==0) showError(paste("No age data matches survey series ",
			SSID,"\n(catch linked to age via 'FEID')",sep=""),as.is=TRUE)
		ages$SVID  = SVID[as.character(ages$FEID)]  # restratified survey IDs
		ages$GC = strata[as.character(ages$FEID)]   # restratified survey IDs
		# In ages for specified GC, some records are missing 'SSID' and 'area'
		zSSID = !is.element(ages$SSID,SSID)
		if (any(zSSID))
			ages$SSID[zSSID] = SSID
		zarea = ages$area<=0 | is.na(ages$area)
		if (any(zarea)) {
			areas = ages$area; names(areas) = ages$EID
			garea = split(areas,ages$GC) # group areas
			farea = sapply(garea,function(x){ # fixed areas
				z = x<=0 | is.na(x)
				if (!any(z)) return(x)
				else if (all(z)) return(rep(0,length(x)))
				else mval = mean(unique(x[!z]),na.rm=TRUE)
				x[z] = mval; return(x)
			})
			for (a in farea)
				ages$area[is.element(ages$EID,names(a))] = a
		}
	}

	# Derive sample unit (e.g., 'TID' or 'SID') data
	sfeid = sapply(split(ages[,"FEID"],ages[,sunit]),function(x){as.character(sort(unique(x)))},simplify=FALSE)
	fcat  = sapply(split(ages[,sweight],ages$FEID),
		function(x){if(all(is.na(x))) 0 else mean(x,na.rm=TRUE)})  # [sweight] by each fishing event (tow)
	scat  = sapply(sfeid,function(x,cvec){sum(cvec[x])},cvec=fcat)# [sweight] by sample unit (i.e., catch or density)
	sdate = sapply(split(ages[,"date"],ages[,sunit]),function(x){as.character(rev(sort(unique(x)))[1])})
	ages$scat  = scat[as.character(ages[,sunit])]                 # populate age data with sample unit [sweight]
	ages$sdate = sdate[as.character(ages[,sunit])]                # populate age data with sample unit dates
	if (ctype=="S"){
		slev = paste(ages$year,pad0(ages$SVID,3),pad0(ages$GC,3),sep=".")    # sample survey year.survey.group
		names(slev) = paste(ages$year,pad0(ages$SVID,3),pad0(ages$GC,3),sep="-")
		attr(slev,"Ylim") = range(ages$year,na.rm=TRUE)
		SLEV = paste(adat$year,pad0(adat$SVID,3),pad0(adat$GC,3),sep=".")
	}
	else {
		slev = convYP(ages$sdate,per)     # sample commercial year.period (e.g. quarter)
		SLEV = convYP(ages$date,per)
	}
	agelev=sort(unique(slev))            # unique sample unit periods
	ages$slev = slev
	if (ctype=="S") {
		ageLEV=sort(unique(SLEV))
		adat$SLEV = SLEV                  # only used for surveys to get all portential stratum areas later
	}
#browser();return()

	# Collect age frequency by sample unit and calculate proportions
	sagetab=array(0,dim=c(plus,length(scat),length(sex),2),
		dimnames=list(age=1:plus,sunit=names(scat),sex=sex,np=c("n","p")))   # age nos. & props. by year-level
	ii=as.character(1:plus)
	for (k in sex) {
		kk=as.character(k)
		kdat=ages[is.element(ages$sex,k),]
		kage=split(kdat$age,kdat[,sunit])
		khis=sapply(kage,function(x){xy=hist(x,plot=FALSE,breaks=seq(0.5,plus+.5,1)); return(list(xy))})
		knat=sapply(khis,function(x){x$counts}); rownames(knat)=ii
		jj=colnames(knat)
		sagetab[ii,jj,kk,"n"] = knat[ii,jj]
	}
	sN=apply(sagetab[,,,"n",drop=FALSE],2,sum)     # total aged fish by sample (thanks Andy)
	for (k in sex) {
		kk=as.character(k)
		sagetab[ii,names(sN),kk,"p"] = t(apply(sagetab[ii,names(sN),kk,"n",drop=FALSE],1,function(x){x/sN}))
	}
	# Sample unit [sweight] (from 'scat' above)
	punits=split(ages[,sunit],ages$slev)
	punit=sapply(punits,function(x){as.character(sort(unique(x)))},simplify=FALSE)

	# proportion sample unit [sweight] by level
	pprop=sapply(punit,simplify=FALSE,function(x,cvec){
		if (sum(cvec[x])==0) cvec[x] else cvec[x]/sum(cvec[x])},cvec=scat)

	# sample unit [sweight] by level (total catch (t) or mean density (kg/km2)
	pcat = atmp = sapply(punit,function(x,cvec){
		xval = cvec[x]/ifelse(sweight=="catch",1000.,1.)
		if (sweight=="density") return(mean(xval,na.rm=TRUE))
		else return(sum(xval,na.rm=TRUE)) },  cvec=scat)
#	if (round(sum(pcat),5)!=round(sum(scat)/ifelse(sweight=="density",1.,1000.),5))
#		showError("Sample unit catch was not allocated correctly")
#browser();return()
	pagetab=array(0,dim=c(plus,length(pprop),length(sex),3),
		dimnames=list(age=1:plus,lev=names(pprop),sex=sex,np=c("n","p","w"))) # nos., props, weighted n or p by year-level
	for (j in names(pprop)){
		jvec=pprop[[j]];  jj=names(jvec)
		jone=rep(1,length(jvec)); names(jone)=jj; jpro=jone/length(jone)
		if (!wSP[1]) jvec=jpro   # if no weighting use equal proportions
		if (all(jvec==0)) next   # happens when survey recorded no weight of strSpp
		for (k in sex) {
			kk=as.character(k)
			ntab=sagetab[,,kk,"n"]; ptab=sagetab[,,kk,"p"]; wtab=sagetab[,,kk,ifelse(wN,"n","p")]
			if(dim(sagetab)[2]==1) {
				ntab=array(ntab,dim=dim(sagetab)[1:2],dimnames=dimnames(sagetab)[1:2])
				ptab=array(ptab,dim=dim(sagetab)[1:2],dimnames=dimnames(sagetab)[1:2])
				wtab=array(wtab,dim=dim(sagetab)[1:2],dimnames=dimnames(sagetab)[1:2])
			}
			kpro=wtab[,jj,drop=FALSE]%*%jvec  # for each sex, weight each level n/p vector and sum
			pagetab[1:plus,j,kk,"n"] = ntab[1:plus,jj,drop=FALSE] %*% jone # row sum
			pagetab[1:plus,j,kk,"p"] = ptab[1:plus,jj,drop=FALSE] %*% jpro # row mean
			pagetab[1:plus,j,kk,"w"] = kpro[1:plus,1]
		}
	}
	psums=apply(pagetab,c(2,4),sum)  # calculate sum by 'lev' and 'np'
	if (wN) {
		inflate=psums[,"n"]/psums[,"w"]
		inflate[is.na(inflate)]=1
		for (k in sex) {
			kk=as.character(k)
			if (length(pprop)==1)
				pagetab[ii,j,kk,"w"] = pagetab[ii,j,kk,"w"] * inflate
			else
				pagetab[ii,names(inflate),kk,"w"] = t(apply(pagetab[ii,names(inflate),kk,"w"],1,function(x){x*inflate}))
		}
	}

	yrs=floor(as.numeric(substring(names(pcat),1,8))-.001)
	names(atmp)=yrs
	acat=sapply(split(pcat,yrs),sum,na.rm=TRUE)    # total sample [sweight] per year
	pvec=pcat/acat[names(atmp)]                    # proportion of annual sample tow [sweight] in level (quarter/stratum)

	# Fishery catch data
	catdat = cdat[!is.na(cdat$date),]
	catdat = catdat[is.element(catdat$year,yrs) & is.element(catdat$major,major),]
	if (ctype=="S"){
		clev = paste(catdat$year,pad0(catdat$SVID,3),pad0(catdat$GC,3),sep=".") # catch level year.survey.group
		names(clev) = paste(catdat$year,pad0(catdat$SVID,3),pad0(catdat$GC,3),sep="-")
		attr(clev,"Ylim") = range(catdat$year,na.rm=TRUE) }
	else
		clev   = convYP(catdat$date,per)       # catch level year.period
	catdat$lev = clev
	#catdat=catdat[is.element(catdat$per,agelev),]  # only look at fishery catch that matches age periods

	# Fishery catch proportions
	if (is.element("catKg",names(catdat)))      Ccat = split(catdat$catKg,catdat$lev)
	else if (is.element("catch",names(catdat))) Ccat = split(catdat$catch,catdat$lev)
	else showError("Fishery catch field 'catKg' or 'catch' is not available")
	PCAT=sapply(Ccat,function(x){sum(x,na.rm=TRUE)/1000.})  # fishery catch (t) for all levels

	# Second reweighting by Quarter if commercial or by Stratum if survey
	if (wSP[2]) {
		if (sweight=="catch")
			Pcat = PCAT[as.character(agelev)]   # only levels that were sampled
		else if  (sweight=="density") {
			alev = paste(ages$year,pad0(ages$SVID,3),pad0(ages$GC,3),sep=".")
			Alst = split(ages$area,alev)        # use area (km^2) from age object
			area = sapply(Alst[agelev],unique)  # get unique stratum area values
			Pcat = sapply(area,mean,na.rm=TRUE) # fornow just use function terminology 'Pcat'
			AREA = sapply(split(adat$area,adat$SLEV),.su) # all potential stratum areas from original age data file (still not complete)
		}
		Atmp = Pcat
		Fyrs = floor(as.numeric(substring(names(Pcat),1,8))-.001)
		names(Atmp)=Fyrs
		Acat = sapply(split(Pcat,Fyrs),sum,na.rm=TRUE)
		Pvec = Pcat/Acat[names(Atmp)]          # proportion of annual fishery tow catch|area in level (quarter|stratum)
#browser();return()
	}

	# Annual proportions weighted by commercial catch|area in levels (quarter|stratum)
	names(yrs)=agelev; YRS=min(yrs):max(yrs)
	agetab=array(0,dim=c(plus,length(YRS),length(sex),4),
		dimnames=list(age=1:plus,year=YRS,sex=sex,np=c("n","p","w","wp")))  # nos., props., weighted n or p by year
	for (j in YRS){
		jj = as.character(j)
		jyr=yrs[is.element(yrs,j)]
		if (length(jyr)==0) next
		jjj = names(jyr)
		jone=rep(1,length(jjj)); names(jone)=jjj; jpro=jone/length(jone)
		if (wSP[2]) jvec=Pvec[jjj]
		else        jvec=jpro   # if no weighting use equal proportions
		for (k in sex) {
			kk=as.character(k)
			#if (length(YRS)==1) {
			if (dim(pagetab)[2]==1) {
				agetab[1:plus,jj,kk,"n"] = pagetab[,,kk,"n"] # transfet n
				agetab[1:plus,jj,kk,"p"] = pagetab[,,kk,"p"] # transfer p
				agetab[1:plus,jj,kk,"w"] = pagetab[,,kk,"w"] # transfer w
			}
			else {
				ntab=pagetab[,,kk,"n"]; ptab=pagetab[,,kk,"p"]; wtab=pagetab[,,kk,"w"]
				kpro=wtab[,jjj,drop=FALSE]%*%jvec  # for each sex, weight each level n/p vector and sum
				agetab[1:plus,jj,kk,"n"] = ntab[1:plus,jjj,drop=FALSE] %*% jone # row sum
				agetab[1:plus,jj,kk,"p"] = ptab[1:plus,jjj,drop=FALSE] %*% jpro # row mean
				agetab[1:plus,jj,kk,"w"] = kpro[1:plus,1]
			}
		}
	}
	asums=apply(agetab,c(2,4),sum)  # calculate sum by 'year' and 'np'
	if (wN) {
		inflate=asums[,"n"]/asums[,"w"]
		inflate[is.na(inflate)]=1
		for (k in sex) {
			kk=as.character(k)
			if (length(YRS)==1)
				agetab[ii,jj,kk,"w"] = agetab[ii,jj,kk,"w"] * inflate
			else
				agetab[ii,names(inflate),kk,"w"] = t(apply(agetab[ii,names(inflate),kk,"w"],1,function(x){x*inflate}))
		}
	}
	aN=apply(agetab,c(2,4),sum)[,"w"]  # calculate sum by 'year' and 'np', then grab 'w'
	aN[is.element(aN,0)]=1
	for (k in sex) {
		kk=as.character(k)
		if (length(YRS)==1)
			agetab[ii,jj,kk,"wp"] = agetab[ii,jj,kk,"w"] / aN
		else
			agetab[ii,names(aN),kk,"wp"] = t(apply(agetab[ii,names(aN),kk,"w"],1,function(x){x/aN}))
	}

	#Summary stats per year
	atid = sapply(split(ages$TID,ages$year),
		function(x){as.character(sort(unique(x)))},simplify=FALSE)          # trips in each year
	Atid = sapply(atid,length)                                             # no. trips in each year
	asid = sapply(split(ages$SID,ages$year),
		function(x){as.character(sort(unique(x)))},simplify=FALSE)          # samples in each year
	Asid = sapply(asid,length)                                             # no. samples in each year

	#Summary stats per level (e.g., quarter/stratum)
	nsid = sapply(split(ages$SID,ages$slev),
		function(x){as.character(sort(unique(x)))},simplify=FALSE)          # samples in each level
	Nsid = sapply(nsid,length)                                             # no. samples in each year
	ntid = sapply(split(ages$TID,ages$slev),
		function(x){as.character(sort(unique(x)))},simplify=FALSE)          # trips in each level
	Ntid = sapply(ntid,length)                                             # no. trips in each year
	Scat = pcat                                                            # sample unit (trip|sample) catch|density
	Fcat = if (sweight=="density") AREA else PCAT                          # fishery commercial catch (complete set) or stratum area

	stats= c("Nsid","Ntid","Scat","Fcat","Psamp")                          # summary table stats

	acyr = range(c(attributes(slev)$Ylim)) #,attributes(clev)$Ylim))       # range of years in age data & catch data
	acy  = acyr[1]:acyr[length(acyr)]                                      # year vector for summary tab
	if (ctype=="S") {
		levs = pad0(sort(unique(ages$GC)),3)
		#levs = sort(unique(paste(ages$SVID,ages$GC,sep=".")))
		lpy  = length(levs) }
	else {
		lpy  = attributes(slev)$Nper                                        # no. levels per year
		levs = 1:lpy }
	sumtab=array(0,dim=c(length(acy),lpy,length(stats)),
		dimnames=list(year=acy, lev=levs, stat=stats))                      # summary table

	for (k in setdiff(stats,"Psamp")) {
		kdat = get(k)
		nxy = names(kdat); dot=regexpr("\\.",nxy)
		if (ctype=="S") {
			#x = substring(nxy,1,dot-1); y = substring(nxy,dot+1) }
			x = substring(nxy,1,4); y = revStr(substring(revStr(nxy),1,3)) }
		else {
			x = as.character(floor(as.numeric(nxy)-.001))
			y = as.character((as.numeric(nxy)-as.numeric(x))*lpy) }
		for (j in levs) {
			#jj = pad0(j,3)
			z=is.element(y,j)
			ii=x[z]
			idat=kdat[z]; names(idat)=ii
			for (i in unique(ii)) 
				sumtab[i,j,k] = sum(idat[is.element(names(idat),i)]) # necessary when more than one survey per year
		}
	}
	if (sweight=="density") { # ensure all stratum areas are populated
#browser();return()
		if (dim(sumtab)[1]>1) { #areas = sumtab[,,"Fcat"]
			areas = apply(sumtab[,,"Fcat"],2,function(x){mean(x[!is.na(x)&x>0])})
			Ftab  = sumtab[,names(areas),"Fcat"]
			Atab  = array(rep(areas,each=dim(Ftab)[[1]]),dim=dim(Ftab),dimnames=dimnames(Ftab))
			Atab[apply(Ftab,1,function(x){all(x==0)}),]=0 # revert to zero for non-sampled years (easier for reporting later)
			sumtab[,,"Fcat"]=Atab
		}
	}
	# proportion of trip:fishery catch (commercial) or sample density:stratum area (meaningless for survey at the moment)
	Psamp = if (sweight=="density") sumtab[,,"Scat"]*sumtab[,,"Fcat"] else sumtab[,,"Scat"]/sumtab[,,"Fcat"]
	Psamp[is.nan(Psamp)]=0
	sumtab[,,"Psamp"]=Psamp

	#---output name---
	wpanam = paste("output-wpa",strSpp,"(",substring(sweight,1,3),")",sep="")
	if (ctype=="S")
		wpanam=paste(c(wpanam,"-ssid(",SSID,")"),collapse="")
	else
		wpanam=paste(c(wpanam,"-tt(",ttype,")"),collapse="")
	if (!is.null(major)) wpanam=paste(c(wpanam,"-major(",paste(major,collapse=""),")"),collapse="")
	#-----------------
#browser();return()

	if (tabs){ #-----Start Tables-----
	sumcsv = sub("output","sumtab",wpanam)
	sumcsv=paste(sumcsv,".csv",sep="")
	cat("Supplementary Table for Weighted Proportions-at-Age","\n\n",file=sumcsv)
	for (k in stats) {
		cat(k,"\n",file=sumcsv,append=TRUE)
		cat("year,",paste(colnames(sumtab),collapse=","),"\n",sep="",file=sumcsv,append=TRUE)
		apply(cbind(year=rownames(sumtab),sumtab[,,k]),1,function(x){cat(paste(x,collapse=","),"\n",sep="",file=sumcsv,append=TRUE)})
		cat("\n",file=sumcsv,append=TRUE) }

	# Coleraine data file: weighted proportions-at-age to CSV
	yy=dimnames(agetab)[[2]]; y=as.numeric(yy)
	wpatab=array(0,dim=c(length(y),5+2*plus), dimnames=list(year=yy,cols=c("year","ntid","nsid","age1","ageN",
		paste("f",pad0(1:plus,2),sep=""),paste("m",pad0(1:plus,2),sep=""))))
	wpatab[yy,"year"]=y
	wpatab[names(Atid),"ntid"]=Atid
	wpatab[names(Asid),"nsid"]=Asid
	wpatab[yy,"age1"]=rep(1,length(y))
	wpatab[yy,"ageN"]=rep(plus,length(y))
	for (k in 2:1) {
		kk=as.character(k)
		jj=paste(switch(k,"m","f"),pad0(1:plus,2),sep="")
		wpatab[yy,jj] = t(agetab[1:plus,yy,kk,zfld])
	}
	wpatxt = wpatab[wpatab[,"nsid"]>0 & !is.na(wpatab[,"nsid"]),,drop=FALSE]
	if (nrow(wpatxt)==0) showError("No records with # SIDs > 0")
	wpacsv = sub("output","coleraine",wpanam)
	wpacsv = paste(wpacsv,".csv",sep="")

	write.table(wpatxt,file=wpacsv,sep=",",na="",row.names=FALSE,col.names=TRUE)
	
	attr(agetab,"wpatab") = wpatxt
	attr(agetab,"sumtab") = sumtab
	save("agetab",file=paste("agetab",strSpp,".rda",sep=""))
	packList(c("acat","pvec","Acat","Pvec","pagetab","sagetab","agetab","sumtab","wpatab","wpatxt"),"PBSfish")

	# ADMB data file: weighted proportions-at-age to DAT
	sidyrs = wpatxt[,"year"]
#browser();return()
	sidtab = agetab[,,,zfld,drop=FALSE]
	sidtab=array(sidtab,dim=dim(sidtab)[1:3],dimnames=dimnames(sidtab)[1:3]) # needed when only 1 year is available
	sidtab=sidtab[,as.character(sidyrs),,drop=FALSE]
	admdat = sub("output","admb",wpanam)
	admdat = paste(admdat,".dat",sep="")
	mess=c("# Proportions-at-age data\n\n",
		"# number of years with ageing data 'NYearAge'\n",length(sidyrs),"\n",
		"# start year\n",min(sidyrs),"\n# end year\n",max(sidyrs),"\n",
		"# number of age classes 'NAge'\n", plus-1+1,"\n",
		"# first age\n",1,"\n# final age\n",plus,"\n\n")
	cat(paste(mess,collapse=""),file=admdat)
	mess=c("# age proportions of males as a matrix data_age_males.\n",
		"#  First row lists the years, then the next 60 rows give the proportions.\n",
		"#  Element [a][t] gives the proportion that are age a-1 in year start_year+t-1.\n",
		"#  Therefore, the matrix has dimensions (final age - first age + 2) * (end year - start year + 1).\n")
	cat(paste(mess,collapse=""),file=admdat,append=TRUE)
#browser();return()
	cat( paste(paste(sidyrs,"      ",sep=""),collapse=""),"\n",file=admdat,append=TRUE)
	if (length(sidyrs)==1)
		mess=paste(show0(format(round(sidtab[,1,"1"],6),scientific=FALSE),6,add2int=TRUE),collapse="  ")
	else
		mess=apply(sidtab[,,"1"],1,function(x){paste(show0(format(round(x,6),scientific=FALSE),6,add2int=TRUE),collapse="  ")})
	cat(paste(mess,collapse="\n"),"\n\n",file=admdat,append=TRUE)
	mess=c("# age proportions of females as a matrix data_age_females.\n",
		"#  Same format as for males.\n")
	cat(paste(mess,collapse=""),file=admdat,append=TRUE)
	cat( paste(paste(sidyrs,"      ",sep=""),collapse=""),"\n",file=admdat,append=TRUE)
	if (length(sidyrs)==1)
		mess=paste(show0(format(round(sidtab[,1,"2"],6),scientific=FALSE),6,add2int=TRUE),collapse="  ")
	else
		mess=apply(sidtab[,,"2"],1,function(x){paste(show0(format(round(x,6),scientific=FALSE),6,add2int=TRUE),collapse="  ")})
	cat(paste(mess,collapse="\n"),"\n\n",file=admdat,append=TRUE)
	mess=c("# number of trips (ntid) and number of samples (nsid) for each year\n",
		"#  (year, ntid, nsid)\n")
	cat(paste(mess,collapse=""),file=admdat,append=TRUE)
	mess=apply(format(wpatxt[,c("year","ntid","nsid"),drop=FALSE]),1,paste,collapse="")
	cat(paste(mess,collapse="\n"),"\n\n",file=admdat,append=TRUE)
	} #-----End Tables-----

	# Test for bubbles of same size
	#z=agetab[,,"1","wp"]==agetab[,,"2","wp"]
	#agetab[,,"1","wp"][z] = -agetab[,,"1","wp"][z]
	#agetab[,,"2","wp"][z] = -agetab[,,"2","wp"][z]

	makeCmat =function(x,colname="Y") {
		matrix(x,ncol=1,dimnames=list(names(x),colname)) }

	# Plot weighted proportions-at-age
	if (plot) {
		plotname = sub("output",paste("age",ptype,sep=""),wpanam)
		plotname = paste(c(plotname,"-sex(",sex,")"),collapse="")
		#plotname=paste(c("age",ptype,strSpp,"-sex(",sex,")"),collapse="")
		#if (ctype=="S")
		#	plotname=paste(c(plotname,"-ssid(",SSID,")"),collapse="")
		#else
		#	plotname=paste(c(plotname,"-tt(",ttype,")"),collapse="")
		#if (!is.null(major)) plotname=paste(c(plotname,"-major(",paste(major,collapse=""),")"),collapse="")
		plotname=paste(plotname,ifelse(wmf,".wmf",ifelse(pix,".png",ifelse(eps,".eps",""))),sep="")

		display = agetab
		reject  = apply(display[,,,"n",drop=FALSE],2:3,sum) < Nmin # do not display these years

		for (k in dimnames(display)$sex)
			display[,reject[,k],k,]=0
		xuse = names(clipVector(apply(reject,1,all),TRUE))
		display = display[,xuse,,,drop=FALSE]
		xlim=extendrange(as.numeric(xuse),f=ifelse(is.null(list(...)$f),0.075,list(...)$f[1]))
		if (length(xuse)==1) xlim = xlim + c(-.5,.5)
		if (is.null(Amin)) 
			Amin = as.numeric(names(clipVector(apply(display[,,,"n"],1,sum),0,1))[1])
		#ylim=extendrange(c(Amin,plus),f=ifelse(is.null(list(...)$f),0.05,rev(list(...)$f)[1]))
		ylim=extendrange(c(0,plus),f=ifelse(is.null(list(...)$f),0.05,rev(list(...)$f)[1]))
		bigBub = min(apply(display[!is.element(rownames(display),plus),,,zfld,drop=FALSE],3,max))   # smallest maximum bubble across sexes

		LAYOUT = 1:3; names(LAYOUT)=c("portrait","landscape","juxstapose")
		nsex   = length(sex)
		nlay   = LAYOUT[layout]
		rows=switch(nlay,nsex,1,1)
		cols=switch(nlay,1,nsex,1)
		shortside=switch(nlay,min(1+1*length(xuse)*0.5,0.80*longside), 0.80*longside, 0.80*longside)
		longside=switch(nlay, longside, min(2+2*length(xuse)*0.5,longside), longside)
#browser();return()
		if (wmf) win.metafile(plotname, width=switch(nlay,shortside,longside,longside),
			height=switch(nlay,longside,shortside,longside))
		else if (pix) {
			ppi=100; pnt=ppi*10/72; zoom=ppi/72
			#zoom = (longside*200)/480      # zoom factor to scale picture up to 200 pixels
			#width=ifelse(layout=="landscape",200*longside,100*longside)
			#height=ifelse(layout=="landscape",100*longside,200*longside)
			#png(plotname, width=width, height=height,pointsize=10*zoom) }
			width=ifelse(layout=="landscape",longside,shortside)
			height=ifelse(layout=="landscape",shortside,longside)
			png(plotname,width=width,height=height,units="in",res=ppi,pointsize=pnt) }
		else if (eps) # postscript orientation is hopelessly F'ed up
			postscript(plotname,width=switch(nlay,shortside,longside,longside),
			height=switch(nlay,longside,shortside,longside),horizontal=FALSE,paper="special")
		else resetGraph()
		expandGraph(mfrow=c(rows,cols),mar=c(2.25,2.5,0.25,0.5),mgp=c(1.5,0.25,0))
		clrs=rep(clrs,length(sex))[1:length(sex)]

		for (k in sex) {
			kk=as.character(k)
			sexBub = max(display[,,kk,zfld,drop=FALSE])     # largest bubble for sex k
			zval = display[,,kk,zfld]
			if (length(xuse)==1) zval=makeCmat(zval,xuse)
			if (!is.null(regimes)) {
				plot(0,0,type="n",axes=FALSE,xlim=xlim,ylim=ylim,xlab="",ylab="")
				x1 = par()$usr[1]; x2 = par()$usr[2]
				for (i in 1:length(regimes)) {
					x = regimes[[i]]; a1=-min(x); a2=-max(x)
					y1lo=a1+x1; y1hi=a2+x1; y2lo=a1+x2; y2hi=a2+x2
					xreg=c(x1,x1,x2,x2); yreg=c(y1lo,y1hi,y2hi,y2lo)
					polygon(xreg,yreg,col="grey92",border=FALSE)
				}
				par(new=TRUE)
			} 
			if (ptype=="bubb") {
				inch = size * (sexBub/bigBub)^powr     # standardise across sexes
				plotBubbles(zval,dnam=TRUE,hide0=TRUE,size=inch,xlim=xlim,ylim=ylim,
					clrs=ifelse(k==0,1,clrs[[k]][1]),las=3,ylab="",tcl=.25,...)
				#plotBubbles(makeCmat(display[,,kk,"n"],xuse),dnam=TRUE,hide0=TRUE,size=inch,xlim=xlim,ylim=ylim,
				#	clrs=ifelse(k==0,1,clrs[[k]][1]),las=3,cex.axis=.8,ylab="",tcl=.25,cpro=T,...)
			}
			if (ptype=="bars") {
				zval[zval>bigBub] = bigBub
				zmax = zval[-plus,]
				if (length(xuse)==1) zmax=makeCmat(zmax,xuse)
				#imax = apply(zmax,2,function(x){x>0 & round(x,5)==round(max(x),5)})
				imax = apply(zmax,2,function(x){x >= quantile(x,0.95) })
				zmax[!imax] = 0
				makePoly = function(amat) {
					amat[is.element(amat,0)] = NA
					xval = as.numeric(dimnames(amat)[[2]]); xdif = diff(xval)[1]
					yval = as.numeric(dimnames(amat)[[1]]); ydif = diff(yval)[1]
					xoff = (amat/bigBub) * (size/2)
					xL   = t(apply(xoff,1,function(x){xval-x})); xLvec = as.vector(xL)
					xR   = t(apply(xoff,1,function(x){xval+x})); xRvec = as.vector(xR)
					xpol = as.vector(rbind(xLvec,xLvec,xRvec,xRvec,rep(NA,length(xLvec))))
					ybox = as.vector(sapply(yval,function(y,yoff){c(y-yoff,y+yoff,y+yoff,y-yoff,NA)},yoff=ydif/2))
					ypol = rep(ybox,length(xval))
					return(list(xpol=xpol,ypol=ypol)) }
				poly1 = makePoly(zval)
				poly2 = makePoly(zmax)
				# TODO: bar width should be nyr * .5/par()$fin[1] for consistency
				sclr = ifelse(k==0,"black",clrs[[k]][1])
				aclr = ifelse(k==0,"grey",clrs[[k]][2])
				#aclr = c(as.vector(col2rgb(sclr)/255),0.5) # transparent alpha colour
				#aclr = rgb(aclr[1],aclr[2],aclr[3],alpha=aclr[4])
				#xlim = xlim + c(- 0.1*diff(par()$usr[1:2]),0)
				plot(0,0,type="n",axes=FALSE,xlim=xlim,ylim=ylim,xlab="",ylab="")
				xpos=intersect(min(xuse):max(xuse),round(pretty(xlim,n=10),5))
				axis(1,at=xpos,las=3,cex.axis=ifelse(is.null(list(...)$cex.axis),0.8,list(...)$cex.axis),tcl=0.25)
				ypos=intersect(0:plus,round(pretty(ylim,n=10),5))
				axis(2,at=ypos,las=1,cex.axis=ifelse(is.null(list(...)$cex.axis),0.8,list(...)$cex.axis),tcl=0.25)
				polygon(poly1$xpol,poly1$ypol,border="gainsboro",col=aclr)
				polygon(poly2$xpol,poly2$ypol,border="gainsboro",col=sclr)
			}
			if (!is.null(cohorts)) {
				for (i in 1:length(cohorts$x)) {
					a = cohorts$y[i]-cohorts$x[i]
					abline(a=a, b=1, col="orangered") 
					text(xlim[2],a+xlim[2],-a,cex=ifelse(pix,0.7,0.8),adj=c(0.6,1.5),col="orangered") 
			} }
			nototab = agetab[,,kk,"n"]
			if (length(YRS)==1)  nototab = makeCmat(nototab,dimnames(agetab)[2])
			noto = apply(nototab,2,sum,na.rm=TRUE); noto = noto[noto>0 & !is.na(noto)]
			#text(as.numeric(names(noto)),(par()$usr[3]+ylim[1])/2,noto,cex=0.9,font=2,col=clrs[[k]][1])
			text(as.numeric(names(noto)),par()$usr[3]+0.06*abs(diff(par()$usr[3:4])),noto,cex=0.9,font=2,col=clrs[[k]][1],adj=1,srt=90)
			box(lwd=ifelse(pix,max(1,floor(zoom/2)),1))
			mtext(paste("Age (",ifelse(k==1,"Males",ifelse(k==2,"Females","Unknown")),")"),
				side=2,line=1.5,las=3,cex=ifelse(is.null(list(...)$cex.lab),1,list(...)$cex.lab))
			#addLabel(0.05,0.05,txt=switch(k,"M","F","U"),cex=1.2,col=clrs[k],font=2)
#browser();return()
			par(new=FALSE)
		}
		if (wmf|pix|eps) dev.off()
		packList(c("Amin","bigBub","reject", "display","plotname"), "PBSfish")
	}
	invisible(agetab) }
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^weightBio

