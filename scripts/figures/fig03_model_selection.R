#!/usr/bin/env Rscript
# Reproduce Figure 3 from the accepted validation-only table.
suppressPackageStartupMessages(library(ggplot2))
args <- commandArgs(trailingOnly = TRUE)
arg_value <- function(flag, default) {
  hit <- grep(paste0("^", flag, "="), args, value = TRUE)
  if (length(hit)) sub(paste0("^", flag, "="), "", hit[[1]]) else default
}
input <- arg_value("--input", "data/derived/evaluation/fig03_validation_metrics.csv")
output_dir <- arg_value("--output-dir", "outputs/figures")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
d <- read.csv(input, check.names = FALSE)
stopifnot(nrow(d) == 10L, identical(d$epoch_index, 0:9),
          which.max(d$ema_ap50_95) == 5L,
          abs(d$ema_ap50_95[5] - 0.5255759074475391) < 1e-12)
long <- rbind(
  data.frame(epoch_index=d$epoch_index, state="Regular", ap=d$regular_ap50_95),
  data.frame(epoch_index=d$epoch_index, state="EMA", ap=d$ema_ap50_95)
)
selected <- long[long$state == "EMA" & long$epoch_index == 4L, ]
p <- ggplot(long, aes(epoch_index, ap, color=state, group=state)) +
  geom_line(linewidth=0.65) + geom_point(size=1.8) +
  geom_point(data=selected, shape=21, size=3.8, stroke=0.9, fill="white") +
  annotate("text", x=4.25, y=selected$ap + 0.012,
           label=sprintf("Selected EMA checkpoint\nAP@50:95 = %.3f", selected$ap),
           hjust=0, size=3.4) +
  scale_color_manual(values=c(Regular="#0072B2", EMA="#D55E00")) +
  scale_x_continuous(breaks=0:9) +
  labs(x="Epoch index", y="Validation COCO AP@50:95", color=NULL) +
  theme_classic(base_size=10, base_family="Arial") + theme(legend.position="top")
ggsave(file.path(output_dir, "Figure3.pdf"), p, width=7.1, height=4.5, device=cairo_pdf)
ggsave(file.path(output_dir, "Figure3.svg"), p, width=7.1, height=4.5, device=svg)
ggsave(file.path(output_dir, "Figure3.png"), p, width=7.1, height=4.5, dpi=300)
cat("PASS: validation-only epochs 0-9; selected epoch-index-4 EMA.\n")
