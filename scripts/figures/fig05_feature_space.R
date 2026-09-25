#!/usr/bin/env Rscript
# Figure 5: display accepted corrected per-image/UMAP/neighborhood results.
# Run from any directory: Rscript <project-root>/fig05_feature_space.R
# Add --v2 for the locked v2 display with observed points but no horizontal
# segments in Panel C. The original v1 outputs remain reproducible by default.
# Add --v3 for the full-width lollipop/table layout in Panel C; this is a
# display-only revision and leaves all accepted analyses and earlier files intact.
# No CLIP, UMAP, model evaluation, nearest-neighbor, or permutation recomputation.

args <- commandArgs(trailingOnly = TRUE)
render_v2 <- "--v2" %in% args
render_v3 <- "--v3" %in% args
if (render_v2 && render_v3) stop("Choose only one Figure 5 display version.")
arg_value <- function(flag, default) {
  hit <- grep(paste0("^", flag, "="), args, value = TRUE)
  if (length(hit)) sub(paste0("^", flag, "="), "", hit[[1]]) else default
}
data_dir <- arg_value("--data-dir", "data/derived/diagnostics")
output_dir <- arg_value("--output-dir", "outputs/figures")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
if (!requireNamespace("ggplot2", quietly = TRUE)) stop("The ggplot2 R package is required.")

source_files <- c(
  image = file.path(data_dir, "per_image_metrics_corrected.csv"),
  vector = file.path(data_dir, "vector_analysis_corrected.csv"),
  tests = file.path(data_dir, "neighborhood_enrichment_corrected.csv")
)
if (!all(file.exists(source_files))) {
  stop("Missing authoritative source: ", paste(source_files[!file.exists(source_files)], collapse = "; "))
}

image <- read.csv(source_files[["image"]], stringsAsFactors = FALSE, check.names = FALSE)
vector <- read.csv(source_files[["vector"]], stringsAsFactors = FALSE, check.names = FALSE)
tests_all <- read.csv(source_files[["tests"]], stringsAsFactors = FALSE, check.names = FALSE)
image_fields <- c("file_name", "ground_truth_objects", "predicted_objects", "F1", "FN_rate")
vector_fields <- c("file_name", "UMAP1", "UMAP2", "ground_truth_objects",
                   "predicted_objects", "F1", "FN_rate")
test_fields <- c("analysis", "group", "space", "eligible_images", "group_images", "k",
                 "enrichment_ratio", "permutation_p_upper")
if (!all(image_fields %in% names(image)) || !all(vector_fields %in% names(vector)) ||
    !all(test_fields %in% names(tests_all))) stop("Accepted diagnostic schema is incomplete.")

if (nrow(image) != 520L || nrow(vector) != 520L ||
    anyDuplicated(image$file_name) || anyDuplicated(vector$file_name) ||
    !setequal(image$file_name, vector$file_name)) {
  stop("The corrected per-image and vector files do not contain the same 520 distinct images.")
}
vector_match <- match(image$file_name, vector$file_name)
if (anyNA(vector_match)) stop("The file_name join lost an image.")
matched_vector <- vector[vector_match, , drop = FALSE]
for (field in c("ground_truth_objects", "predicted_objects", "F1", "FN_rate")) {
  if (!isTRUE(all.equal(image[[field]], matched_vector[[field]],
                        tolerance = 1e-12, check.attributes = FALSE))) {
    stop("Corrected image and vector files disagree on field: ", field)
  }
}

joined <- data.frame(
  file_name = image$file_name,
  UMAP1 = matched_vector$UMAP1,
  UMAP2 = matched_vector$UMAP2,
  F1 = image$F1,
  FN_rate = image$FN_rate,
  ground_truth_objects = image$ground_truth_objects,
  predicted_objects = image$predicted_objects,
  gt_present = image$ground_truth_objects > 0,
  no_detection = image$predicted_objects == 0,
  stringsAsFactors = FALSE
)
joined$low_f1_group <- !is.na(joined$F1) & joined$F1 <= 0.25
joined$high_fn_group <- !is.na(joined$FN_rate) & joined$FN_rate >= 0.75

if (nrow(joined) != 520L || anyDuplicated(joined$file_name) ||
    any(!is.finite(joined$UMAP1)) || any(!is.finite(joined$UMAP2)) ||
    sum(joined$gt_present) != 490L || sum(!joined$gt_present) != 30L ||
    sum(joined$no_detection) != 59L ||
    any(!is.na(joined$F1[!joined$gt_present])) ||
    any(!is.na(joined$FN_rate[!joined$gt_present])) ||
    anyNA(joined$F1[joined$gt_present]) ||
    anyNA(joined$FN_rate[joined$gt_present]) ||
    sum(joined$F1[joined$gt_present] == 0) != 83L ||
    sum(joined$low_f1_group) != 83L ||
    sum(joined$high_fn_group) != 95L ||
    any(joined$F1[joined$gt_present] < 0 | joined$F1[joined$gt_present] > 1) ||
    any(joined$FN_rate[joined$gt_present] < 0 |
        joined$FN_rate[joined$gt_present] > 1)) {
  stop("Corrected full-test image/undefined/threshold validation failed.")
}
# In particular, preserve all zero-detection images through the join.
if (sum(joined$no_detection & joined$gt_present) != 32L ||
    sum(joined$no_detection & !joined$gt_present) != 27L) {
  stop("The 59 no-detection images were not fully retained.")
}

tests <- tests_all[tests_all$analysis == "corrected", , drop = FALSE]
expected <- data.frame(
  group = c("F1_le_0.25", "F1_le_0.25", "FN_rate_ge_0.75", "FN_rate_ge_0.75"),
  space = c("CLIP_cosine", "UMAP_euclidean", "CLIP_cosine", "UMAP_euclidean"),
  ratio = c(0.9723479282985601, 0.9004995592124597,
            0.9528107502799552, 0.9272564389697648),
  p = c(0.588, 0.895, 0.702, 0.869),
  n = c(83L, 83L, 95L, 95L),
  stringsAsFactors = FALSE
)
keys <- paste(tests$group, tests$space, sep = "|")
expected_keys <- paste(expected$group, expected$space, sep = "|")
if (nrow(tests) != 4L || anyDuplicated(keys) || !setequal(keys, expected_keys)) {
  stop("The four accepted corrected neighborhood tests are not present exactly once.")
}
tests <- tests[match(expected_keys, keys), , drop = FALSE]
if (any(tests$k != 15L) || any(tests$eligible_images != 490L) ||
    any(tests$group_images != expected$n) ||
    any(abs(tests$enrichment_ratio - expected$ratio) > 1e-12) ||
    any(abs(tests$permutation_p_upper - expected$p) > 1e-12) ||
    any(tests$permutation_p_upper < 0.05)) {
  stop("Accepted k=15 ratios, group sizes, or permutation p-values failed validation.")
}

# Both image panels are drawn from this one table and the same limits.
x_limits <- range(joined$UMAP1) + c(-1, 1) * 0.04 * diff(range(joined$UMAP1))
y_limits <- range(joined$UMAP2) + c(-1, 1) * 0.04 * diff(range(joined$UMAP2))
if (length(x_limits) != 2L || length(y_limits) != 2L ||
    any(!is.finite(x_limits)) || any(!is.finite(y_limits)) ||
    x_limits[[1L]] >= x_limits[[2L]] || y_limits[[1L]] >= y_limits[[2L]]) {
  stop("Shared UMAP coordinate limits are invalid.")
}

# All gates have passed. Write one transparent joined plotting table; use the
# authoritative test rows directly rather than a redundant copied test CSV.
if (!render_v2 && !render_v3) {
  write.csv(joined, file.path(output_dir, "fig05_image_metrics.csv"), row.names = FALSE, na = "")
}

defined <- joined[joined$gt_present, , drop = FALSE]
undefined <- joined[!joined$gt_present, , drop = FALSE]
poor_color <- "#29477D"
good_color <- "#DCE9F0"
undefined_fill <- "#F2F3F4"
undefined_outline <- "#6A7077"

common_scatter <- function(value_field, panel_title, legend_title, reverse_colors = FALSE) {
  low_color <- if (reverse_colors) good_color else poor_color
  high_color <- if (reverse_colors) poor_color else good_color
  ggplot2::ggplot() +
    ggplot2::geom_point(
      data = defined,
      ggplot2::aes(x = UMAP1, y = UMAP2, colour = .data[[value_field]]),
      size = 1.8, alpha = 0.80, show.legend = TRUE
    ) +
    ggplot2::geom_point(
      data = undefined,
      ggplot2::aes(x = UMAP1, y = UMAP2, shape = "Undefined (no GT)"),
      size = 2.0, fill = undefined_fill, colour = undefined_outline,
      stroke = 0.55, alpha = 1
    ) +
    ggplot2::scale_colour_gradient(low = low_color, high = high_color,
                                   limits = c(0, 1), breaks = c(0, 0.25, 0.5, 0.75, 1),
                                   name = legend_title) +
    ggplot2::scale_shape_manual(values = c("Undefined (no GT)" = 21), name = NULL) +
    ggplot2::guides(
      colour = ggplot2::guide_colourbar(order = 1, title.position = "top",
                                       barwidth = grid::unit(1.65, "in"),
                                       barheight = grid::unit(0.12, "in")),
      shape = ggplot2::guide_legend(order = 2, override.aes = list(
        fill = undefined_fill, colour = undefined_outline, size = 2.4))
    ) +
    ggplot2::coord_equal(xlim = x_limits, ylim = y_limits, expand = FALSE) +
    ggplot2::labs(title = panel_title, x = "UMAP 1", y = "UMAP 2") +
    ggplot2::theme_classic(base_family = "Arial", base_size = 10) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", size = 12, color = "#253746",
                                         margin = ggplot2::margin(b = 5)),
      axis.title = ggplot2::element_text(size = 10, color = "#253746"),
      axis.text = ggplot2::element_text(size = 9, color = "#253746"),
      axis.line = ggplot2::element_line(color = "#5A6975", linewidth = 0.4),
      axis.ticks = ggplot2::element_line(color = "#5A6975", linewidth = 0.4),
      legend.position = "bottom",
      legend.box = "vertical",
      legend.title = ggplot2::element_text(size = 8.5),
      legend.text = ggplot2::element_text(size = 8),
      legend.key.height = grid::unit(0.16, "in"),
      plot.margin = ggplot2::margin(8, 8, 5, 8)
    )
}

# Dark blue represents poorer performance in BOTH panels: low F1 in A,
# high false-negative rate in B. Hollow gray points are undefined, not zero.
plot_a <- common_scatter("F1", "A  Per-image F1", "Per-image F1", FALSE)
plot_b <- common_scatter("FN_rate", "B  False-negative rate", "False-negative rate", TRUE)

tests$display_group <- c("Low F1 - CLIP", "Low F1 - UMAP",
                         "High FN - CLIP", "High FN - UMAP")
tests$display_group <- factor(tests$display_group,
                              levels = rev(c("Low F1 - CLIP", "Low F1 - UMAP",
                                             "High FN - CLIP", "High FN - UMAP")))
tests$direct_label <- sprintf("%.3f   p = %.3f",
                              tests$enrichment_ratio, tests$permutation_p_upper)
threshold_symbol <- if (render_v2 || render_v3) "\u2265" else ">="
count_note <- sprintf(paste0("F1 = 0: %d/%d GT images     FN rate ",
                             threshold_symbol, " 0.75: %d/%d GT images"),
                      sum(joined$F1[joined$gt_present] == 0), sum(joined$gt_present),
                      sum(joined$high_fn_group), sum(joined$gt_present))

plot_c <- ggplot2::ggplot(tests,
                          ggplot2::aes(y = display_group, x = enrichment_ratio)) +
  ggplot2::geom_vline(xintercept = 1, linetype = "22", linewidth = 0.4,
                      color = "#798994")
if (!render_v2 && !render_v3) {
  plot_c <- plot_c +
    ggplot2::geom_segment(ggplot2::aes(x = 1, xend = enrichment_ratio,
                                       yend = display_group),
                          linewidth = 0.75, color = poor_color)
}
plot_c <- plot_c +
  ggplot2::geom_point(size = 2.5, color = poor_color) +
  ggplot2::geom_text(ggplot2::aes(label = direct_label),
                     x = 1.03, hjust = 0, size = 3.0, color = "#253746",
                     family = "Arial") +
  ggplot2::scale_x_continuous(limits = c(0.83, 1.28),
                              breaks = c(0.85, 0.90, 0.95, 1.00)) +
  ggplot2::labs(title = "C  Local neighborhood enrichment (k = 15)",
                subtitle = count_note,
                x = "Observed / expected same-group neighbors", y = NULL) +
  ggplot2::theme_classic(base_family = "Arial", base_size = 10) +
  ggplot2::theme(
    plot.title = ggplot2::element_text(face = "bold", size = 12,
                                       color = "#253746", margin = ggplot2::margin(b = 4)),
    plot.subtitle = ggplot2::element_text(size = 9.3, color = "#40515E",
                                          margin = ggplot2::margin(b = 6)),
    axis.title.x = ggplot2::element_text(size = 10.5, color = "#253746"),
    axis.text = ggplot2::element_text(size = 9.3, color = "#253746"),
    axis.line = ggplot2::element_line(color = "#5A6975", linewidth = 0.4),
    axis.ticks.y = ggplot2::element_blank(),
    plot.margin = ggplot2::margin(8, 12, 8, 8)
  )

# V3 changes only Panel C's geometry. The horizontal segment runs from each
# saved observed ratio to the null reference (1.0); it is not an interval.
# A/B plots, the accepted tests, and all validation gates above are unchanged.
draw_panel_c_v3 <- function() {
  grid::pushViewport(grid::viewport(layout.pos.row = 2, layout.pos.col = 1:2))
  on.exit(grid::popViewport())
  ink <- "#253746"
  secondary <- "#40515E"
  muted <- "#798994"
  at_x <- function(ratio) 0.30 + (ratio - 0.88) / (1.02 - 0.88) * 0.40
  rows <- c(0.61, 0.50, 0.39, 0.28)
  gt_total <- sum(joined$gt_present)

  grid::grid.text("C  Local neighborhood enrichment (k = 15)",
                  x = 0.025, y = 0.94, default.units = "npc", just = "left",
                  gp = grid::gpar(fontfamily = "Arial", fontsize = 12, fontface = "bold", col = ink))
  grid::grid.text(sprintf("F1 = 0: %d/%d GT images",
                          sum(joined$F1[joined$gt_present] == 0), gt_total),
                  x = 0.025, y = 0.83, default.units = "npc", just = "left",
                  gp = grid::gpar(fontfamily = "Arial", fontsize = 9.3, col = secondary))
  grid::grid.text(sprintf("FN rate \u2265 0.75: %d/%d GT images",
                          sum(joined$high_fn_group), gt_total),
                  x = 0.52, y = 0.83, default.units = "npc", just = "left",
                  gp = grid::gpar(fontfamily = "Arial", fontsize = 9.3, col = secondary))

  grid::grid.text("Observed / expected ratio", x = 0.50, y = 0.72,
                  default.units = "npc",
                  gp = grid::gpar(fontfamily = "Arial", fontsize = 8.4, col = secondary))
  grid::grid.text("Ratio", x = 0.79, y = 0.72, default.units = "npc",
                  gp = grid::gpar(fontfamily = "Arial", fontsize = 9, fontface = "bold", col = ink))
  grid::grid.text("p-value", x = 0.92, y = 0.72, default.units = "npc",
                  gp = grid::gpar(fontfamily = "Arial", fontsize = 9, fontface = "bold", col = ink))

  null_x <- at_x(1.0)
  grid::grid.lines(x = c(null_x, null_x), y = c(0.20, 0.675),
                   default.units = "npc",
                   gp = grid::gpar(col = muted, lwd = 0.85, lty = "22"))
  for (i in seq_len(nrow(tests))) {
    observed_x <- at_x(tests$enrichment_ratio[i])
    grid::grid.text(as.character(tests$display_group[i]), x = 0.025, y = rows[i],
                    default.units = "npc", just = "left",
                    gp = grid::gpar(fontfamily = "Arial", fontsize = 9.5, col = ink))
    grid::grid.lines(x = c(observed_x, null_x), y = rep(rows[i], 2),
                     default.units = "npc",
                     gp = grid::gpar(col = poor_color, lwd = 1.15, lineend = "butt"))
    grid::grid.points(x = observed_x, y = rows[i], default.units = "npc",
                      pch = 16, size = grid::unit(0.085, "in"),
                      gp = grid::gpar(col = poor_color))
    grid::grid.text(sprintf("%.3f", tests$enrichment_ratio[i]), x = 0.79, y = rows[i],
                    default.units = "npc",
                    gp = grid::gpar(fontfamily = "Arial", fontsize = 9.5, col = ink))
    grid::grid.text(sprintf("%.3f", tests$permutation_p_upper[i]), x = 0.92, y = rows[i],
                    default.units = "npc",
                    gp = grid::gpar(fontfamily = "Arial", fontsize = 9.5, col = ink))
  }
  grid::grid.lines(x = c(at_x(0.88), at_x(1.02)), y = c(0.18, 0.18),
                   default.units = "npc", gp = grid::gpar(col = "#5A6975", lwd = 0.55))
  for (tick in c(0.90, 0.95, 1.00)) {
    tick_x <- at_x(tick)
    grid::grid.lines(x = c(tick_x, tick_x), y = c(0.18, 0.16),
                     default.units = "npc", gp = grid::gpar(col = "#5A6975", lwd = 0.55))
    grid::grid.text(sprintf("%.2f", tick), x = tick_x, y = 0.115,
                    default.units = "npc",
                    gp = grid::gpar(fontfamily = "Arial", fontsize = 8.8, col = ink))
  }
  grid::grid.text("Segments indicate distance to null, not uncertainty.",
                  x = 0.025, y = 0.035, default.units = "npc", just = "left",
                  gp = grid::gpar(fontfamily = "Arial", fontsize = 7.5, col = secondary))
}

draw_figure <- function() {
  grid::grid.newpage()
  grid::pushViewport(grid::viewport(layout = grid::grid.layout(
    2, 2, heights = grid::unit(c(0.64, 0.36), "null"),
    widths = grid::unit(c(0.5, 0.5), "null"))))
  print(plot_a, vp = grid::viewport(layout.pos.row = 1, layout.pos.col = 1), newpage = FALSE)
  print(plot_b, vp = grid::viewport(layout.pos.row = 1, layout.pos.col = 2), newpage = FALSE)
  if (render_v3) {
    draw_panel_c_v3()
  } else {
    print(plot_c, vp = grid::viewport(layout.pos.row = 2, layout.pos.col = 1:2), newpage = FALSE)
  }
  grid::popViewport()
}

width <- 7.4
height <- 7.2
figure_stem <- if (render_v3) "Figure5_draft_v3" else if (render_v2) "Figure5_draft_v2" else "Figure5_draft"
grDevices::cairo_pdf(file.path(output_dir, paste0(figure_stem, ".pdf")), width = width, height = height,
                     family = "Arial", bg = "white")
draw_figure()
grDevices::dev.off()
grDevices::svg(file.path(output_dir, paste0(figure_stem, ".svg")), width = width, height = height,
               family = "Arial", bg = "white")
draw_figure()
grDevices::dev.off()
grDevices::png(file.path(output_dir, paste0(figure_stem, ".png")), width = width, height = height,
               units = "in", res = 300, type = "cairo", bg = "white")
draw_figure()
grDevices::dev.off()

cat(sprintf("PASS: %d images, %d GT, %d no GT, %d no detections; F1=0: %d; FN>=0.75: %d; four accepted k=15 tests.\n",
            nrow(joined), sum(joined$gt_present), sum(!joined$gt_present),
            sum(joined$no_detection), sum(joined$F1[joined$gt_present] == 0),
            sum(joined$high_fn_group)))
cat(if (render_v3) {
  "Figure 5 v3 PDF/SVG/PNG written; existing joined CSV unchanged; no UMAP or permutation computation.\n"
} else if (render_v2) {
  "Figure 5 v2 PDF/SVG/PNG written; existing joined CSV unchanged; no UMAP or permutation computation.\n"
} else {
  "Figure 5 PDF/SVG/PNG and joined CSV written; no UMAP or permutation computation.\n"
})
