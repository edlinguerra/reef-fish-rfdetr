#!/usr/bin/env Rscript
# Reproduce public-safe numerical Panel A of Figure 6. Illustrative archive
# photographs and saved renders are intentionally excluded.
suppressPackageStartupMessages(library(ggplot2))
args<-commandArgs(trailingOnly=TRUE)
arg_value<-function(flag,default){hit<-grep(paste0("^",flag,"="),args,value=TRUE);if(length(hit))sub(paste0("^",flag,"="),"",hit[[1]])else default}
input<-arg_value("--input","figures/data/archive_scale_summary.csv"); output_dir<-arg_value("--output-dir","outputs/figures"); dir.create(output_dir,recursive=TRUE,showWarnings=FALSE)
d<-read.csv(input,check.names=FALSE); stopifnot(d$value[d$measure=="image_records"]==198965L,d$value[d$measure=="saved_detections"]==81601L)
d$label<-c("198,965\nimage records","81,601\nsaved detections")[match(d$measure,c("image_records","saved_detections"))]
p<-ggplot(d,aes(factor(measure,levels=c("image_records","saved_detections")),value,fill=measure))+geom_col(width=.62,show.legend=FALSE)+geom_text(aes(label=label),vjust=-.25,size=5,lineheight=.9)+scale_fill_manual(values=c(image_records="#0072B2",saved_detections="#E69F00"))+expand_limits(y=220000)+labs(title="Archive-scale application, 2024-2025",x=NULL,y="Records")+theme_classic(base_size=11,base_family="Arial")+theme(axis.text.x=element_blank(),axis.ticks.x=element_blank())
ggsave(file.path(output_dir,"Figure6_panel_A.pdf"),p,width=5,height=4,device=cairo_pdf); ggsave(file.path(output_dir,"Figure6_panel_A.png"),p,width=5,height=4,dpi=300)
cat("PASS: 198,965 image records and 81,601 saved detections.\n")
