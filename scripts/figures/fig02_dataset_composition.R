#!/usr/bin/env Rscript
# Reproduce public-safe numerical Panels A-B of Figure 2. Panel C uses
# author-selected SAMP photographs and is intentionally excluded.
suppressPackageStartupMessages(library(ggplot2))
args <- commandArgs(trailingOnly=TRUE)
arg_value <- function(flag, default) { hit<-grep(paste0("^",flag,"="),args,value=TRUE); if(length(hit)) sub(paste0("^",flag,"="),"",hit[[1]]) else default }
input <- arg_value("--input","data/derived/dataset/fig02_class_support.csv")
output_dir <- arg_value("--output-dir","outputs/figures")
dir.create(output_dir,recursive=TRUE,showWarnings=FALSE)
d<-read.csv(input,check.names=FALSE)
stopifnot(nrow(d)==52L,all(d$training_support==d$SAMP_training_support+d$iNaturalist_training_support))
split<-data.frame(partition=factor(c("Training","Validation","Held-out test"),levels=c("Training","Validation","Held-out test")),images=c(8517,698,520))
pa<-ggplot(split,aes(partition,images,fill=partition))+geom_col(show.legend=FALSE)+geom_text(aes(label=format(images,big.mark=",")),vjust=-0.3)+scale_fill_manual(values=c("#0072B2","#56B4E9","#E69F00"))+labs(title="A  Pre-augmentation partitions",x=NULL,y="Images")+theme_classic(base_size=10,base_family="Arial")
long<-rbind(data.frame(class=d$operational_class,source="SAMP",support=d$SAMP_training_support),data.frame(class=d$operational_class,source="iNaturalist",support=d$iNaturalist_training_support)); order<-d$operational_class[order(d$training_support)]; long$class<-factor(long$class,levels=order)
pb<-ggplot(long,aes(class,support,fill=source))+geom_col()+coord_flip()+scale_y_sqrt()+scale_fill_manual(values=c(SAMP="#0072B2",iNaturalist="#E69F00"),name="Image source")+labs(title="B  Training support by operational class and source",x=NULL,y="Training source images containing class (square-root scale)")+theme_classic(base_size=7,base_family="Arial")
cairo_pdf(file.path(output_dir,"Figure2_public_panels_AB.pdf"),width=9,height=10); grid::grid.newpage(); grid::pushViewport(grid::viewport(layout=grid::grid.layout(2,1,heights=grid::unit(c(1,3),"null")))); print(pa,vp=grid::viewport(layout.pos.row=1)); print(pb,vp=grid::viewport(layout.pos.row=2)); dev.off()
cat("PASS: numerical Panels A-B; Panel C excluded because source photographs are not redistributed.\n")
