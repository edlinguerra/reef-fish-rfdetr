#!/usr/bin/env Rscript
# Reproduce the accepted two-panel Figure 4 from plot-ready tables.
suppressPackageStartupMessages(library(ggplot2))
args <- commandArgs(trailingOnly = TRUE)
arg_value <- function(flag, default) {
  hit <- grep(paste0("^", flag, "="), args, value = TRUE)
  if (length(hit)) sub(paste0("^", flag, "="), "", hit[[1]]) else default
}
data_dir <- arg_value("--data-dir", "figures/data")
output_dir <- arg_value("--output-dir", "outputs/figures")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
m <- read.csv(file.path(data_dir, "fig04_confusion_matrix.csv"), check.names=FALSE)
o <- read.csv(file.path(data_dir, "fig04_gt_outcomes.csv"), check.names=FALSE)
stopifnot(nrow(m) == 52L*53L, sum(o$count) == 1846L,
          identical(as.integer(o$count), c(1237L,112L,497L)))
m$gt_label <- factor(m$gt_label, levels=rev(unique(m$gt_label[order(m$gt_order)])))
m$pred_label <- factor(m$pred_label, levels=unique(m$pred_label[order(m$pred_order)]))
pa <- ggplot(m, aes(pred_label, gt_label, fill=within_row_proportion)) +
  geom_tile(color="white", linewidth=0.05) +
  scale_fill_viridis_c(option="C", limits=c(0,1), name="Row proportion") +
  labs(title="A  Class-level assignments", x="Predicted category", y="Ground-truth category") +
  theme_minimal(base_size=7, base_family="Arial") +
  theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5), panel.grid=element_blank())
po <- ggplot(o, aes(reorder(outcome, count), count, fill=outcome)) +
  geom_col(width=0.7, show.legend=FALSE) + coord_flip() +
  geom_text(aes(label=count), hjust=-0.15, size=3.2) +
  scale_fill_manual(values=c("Correct-class match"="#0072B2","Wrong-class match"="#E69F00","Unmatched ground truth"="#CC79A7")) +
  expand_limits(y=max(o$count)*1.12) +
  labs(title="B  Ground-truth outcomes (n = 1,846)", x=NULL, y="Objects") +
  theme_classic(base_size=9, base_family="Arial")
draw <- function() {
  grid::grid.newpage()
  grid::pushViewport(grid::viewport(layout=grid::grid.layout(1,2,widths=grid::unit(c(3.2,1),"null"))))
  print(pa, vp=grid::viewport(layout.pos.row=1,layout.pos.col=1))
  print(po, vp=grid::viewport(layout.pos.row=1,layout.pos.col=2))
}
cairo_pdf(file.path(output_dir,"Figure4.pdf"), width=10.5, height=8.0); draw(); dev.off()
svg(file.path(output_dir,"Figure4.svg"), width=10.5, height=8.0); draw(); dev.off()
png(file.path(output_dir,"Figure4.png"), width=3150, height=2400, res=300); draw(); dev.off()
cat("PASS: 52 classes plus No match; 1,846 GT outcomes.\n")
