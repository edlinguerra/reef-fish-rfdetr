# Sensitivity analysis after removing the confirmed train-test duplicate.
#
# This script is intentionally non-destructive. It reads the authoritative
# corrected full-test events, per-image metrics, and saved CLIP embeddings,
# removes one named image, and writes only new *_sensitivity artifacts.

suppressPackageStartupMessages({
  library(jsonlite)
  library(dplyr)
  library(tidyr)
  library(tibble)
  library(ggplot2)
  library(readr)
  library(uwot)
})

options(stringsAsFactors = FALSE)

args <- commandArgs(trailingOnly = TRUE)
arg_value <- function(flag, default) {
  hit <- grep(paste0("^", flag, "="), args, value = TRUE)
  if (length(hit) == 0L) default else sub(paste0("^", flag, "="), "", hit[[1]])
}
evaluation_dir <- normalizePath(arg_value("--evaluation-dir", "data/derived/evaluation"), mustWork = TRUE)
diagnostic_dir <- normalizePath(arg_value("--diagnostic-dir", "data/derived/diagnostics"), mustWork = TRUE)
output_dir <- arg_value("--output-dir", "outputs/sensitivity")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
setwd(output_dir)

target_image <- "Sparisoma-aurofrenatum_50_jpeg.rf.01a354eadafa43e014231167f64c0302.jpg"

gt <- fromJSON(file.path(evaluation_dir, "test_ground_truth.coco.json"), flatten = TRUE)
categories <- gt$categories |>
  as_tibble() |>
  filter(id != 0L) |>
  transmute(category_id = as.character(id), class_name = name)

events_520 <- read_csv(file.path(diagnostic_dir, "confusion_events_corrected.csv"), show_col_types = FALSE)
metrics_520 <- read_csv(file.path(diagnostic_dir, "per_image_metrics_corrected.csv"), show_col_types = FALSE)
embeddings_520 <- read_csv(file.path(diagnostic_dir, "vector_analysis_embeddings.csv"), show_col_types = FALSE)
vector_520 <- read_csv(file.path(diagnostic_dir, "vector_analysis_corrected.csv"), show_col_types = FALSE)

stopifnot(
  nrow(metrics_520) == 520L,
  nrow(embeddings_520) == 520L,
  nrow(vector_520) == 520L,
  sum(metrics_520$file_name == target_image) == 1L,
  sum(embeddings_520$file_name == target_image) == 1L,
  sum(events_520$file_name == target_image) == 1L,
  events_520$event_type[events_520$file_name == target_image] == "correct_match"
)

events_519 <- events_520 |>
  filter(file_name != target_image)
metrics_519 <- metrics_520 |>
  filter(file_name != target_image)
embeddings_519 <- embeddings_520 |>
  filter(file_name != target_image)

stopifnot(
  nrow(metrics_519) == 519L,
  nrow(embeddings_519) == 519L,
  sum(metrics_519$TP) == sum(metrics_520$TP) - 1L,
  sum(metrics_519$FP) == sum(metrics_520$FP),
  sum(metrics_519$FN) == sum(metrics_520$FN)
)

summarize_metrics <- function(data, analysis) {
  data |>
    summarise(
      analysis = analysis,
      images = n(),
      images_with_defined_precision = sum(!is.na(precision)),
      images_with_defined_recall = sum(!is.na(recall)),
      images_with_defined_F1 = sum(!is.na(F1)),
      zero_performance_images = sum(F1 == 0, na.rm = TRUE),
      TP = sum(TP),
      FP = sum(FP),
      FN = sum(FN),
      micro_precision = TP / (TP + FP),
      micro_recall = TP / (TP + FN),
      micro_F1 = 2 * micro_precision * micro_recall / (micro_precision + micro_recall),
      mean_defined_image_F1 = mean(F1, na.rm = TRUE),
      median_defined_image_F1 = median(F1, na.rm = TRUE),
      mean_defined_image_FN_rate = mean(FN_rate, na.rm = TRUE),
      median_defined_image_FN_rate = median(FN_rate, na.rm = TRUE)
    )
}

per_image_summary <- bind_rows(
  summarize_metrics(metrics_520, "corrected_520"),
  summarize_metrics(metrics_519, "cleaned_519")
)

numeric_columns <- names(per_image_summary)[
  vapply(per_image_summary, is.numeric, logical(1))
]
difference_row <- per_image_summary[2, ]
difference_row$analysis <- "difference_519_minus_520"
for (column in numeric_columns) {
  difference_row[[column]] <- per_image_summary[[column]][2] - per_image_summary[[column]][1]
}
per_image_summary <- bind_rows(per_image_summary, difference_row)

write_csv(metrics_519, "per_image_metrics_519_sensitivity.csv")
write_csv(per_image_summary, "per_image_metric_summary_sensitivity.csv")

event_summary <- function(events, analysis) {
  tp <- sum(events$event_type == "correct_match")
  confusions <- sum(events$event_type == "class_confusion")
  unmatched_fp <- sum(events$event_type == "unmatched_prediction")
  unmatched_fn <- sum(events$event_type == "unmatched_ground_truth")
  tibble(
    analysis = analysis,
    images = ifelse(analysis == "corrected_520", 520L, 519L),
    TP = tp,
    FP = unmatched_fp + confusions,
    FN = unmatched_fn + confusions,
    class_confusions = confusions,
    unmatched_predictions = unmatched_fp,
    unmatched_ground_truth = unmatched_fn
  )
}

confusion_totals <- bind_rows(
  event_summary(events_520, "corrected_520"),
  event_summary(events_519, "cleaned_519")
)
confusion_difference <- confusion_totals[2, ]
confusion_difference$analysis <- "difference_519_minus_520"
for (column in names(confusion_totals)[-1]) {
  confusion_difference[[column]] <- confusion_totals[[column]][2] - confusion_totals[[column]][1]
}
confusion_totals <- bind_rows(confusion_totals, confusion_difference)
write_csv(confusion_totals, "confusion_totals_sensitivity.csv")

labels <- c(categories$category_id, "background")
build_matrix <- function(events, analysis) {
  events |>
    count(gt, pred, name = "n") |>
    complete(gt = labels, pred = labels, fill = list(n = 0L)) |>
    left_join(categories, by = c("gt" = "category_id")) |>
    rename(gt_name = class_name) |>
    left_join(categories, by = c("pred" = "category_id")) |>
    rename(pred_name = class_name) |>
    mutate(
      gt_name = ifelse(is.na(gt_name), gt, gt_name),
      pred_name = ifelse(is.na(pred_name), pred, pred_name),
      analysis = analysis
    ) |>
    group_by(analysis, gt_name) |>
    mutate(
      row_total = sum(n),
      pct = ifelse(row_total > 0, 100 * n / row_total, 0)
    ) |>
    ungroup()
}

matrix_520 <- build_matrix(events_520, "corrected_520")
matrix_519 <- build_matrix(events_519, "cleaned_519")
write_csv(
  matrix_519 |> select(gt, pred, n, gt_name, pred_name),
  "confusion_matrix_counts_519_sensitivity.csv"
)
write_csv(
  matrix_519 |> select(gt, pred, n, gt_name, pred_name, row_total, pct),
  "confusion_matrix_normalized_519_sensitivity.csv"
)

interpret_confusion <- function(events, analysis) {
  gt_events <- events |>
    filter(gt != "background")
  per_class <- gt_events |>
    count(gt, pred, name = "n") |>
    group_by(gt) |>
    summarise(
      row_total = sum(n),
      diagonal = sum(n[pred == gt]),
      false_negative_background = sum(n[pred == "background"]),
      class_confusion = sum(n[pred != "background" & pred != gt]),
      largest_cell = max(n),
      diagonal_is_largest = diagonal == largest_cell,
      diagonal_fraction = diagonal / row_total,
      .groups = "drop"
    )
  list(
    overall = tibble(
      analysis = analysis,
      ground_truth_objects = nrow(gt_events),
      correct_diagonal = sum(gt_events$gt == gt_events$pred),
      false_negative_background = sum(gt_events$pred == "background"),
      class_confusions = sum(gt_events$pred != "background" & gt_events$pred != gt_events$gt),
      diagonal_fraction = mean(gt_events$gt == gt_events$pred),
      false_negative_background_fraction = mean(gt_events$pred == "background"),
      class_confusion_fraction = mean(gt_events$pred != "background" & gt_events$pred != gt_events$gt),
      classes_with_ground_truth = nrow(per_class),
      classes_where_diagonal_is_largest = sum(per_class$diagonal_is_largest),
      median_class_diagonal_fraction = median(per_class$diagonal_fraction),
      mean_class_diagonal_fraction = mean(per_class$diagonal_fraction)
    ),
    per_class = per_class |>
      mutate(analysis = analysis) |>
      relocate(analysis)
  )
}

interpret_520 <- interpret_confusion(events_520, "corrected_520")
interpret_519 <- interpret_confusion(events_519, "cleaned_519")
interpretation_overall <- bind_rows(interpret_520$overall, interpret_519$overall)
interpretation_classes <- bind_rows(interpret_520$per_class, interpret_519$per_class)
write_csv(interpretation_overall, "confusion_interpretation_sensitivity.csv")
write_csv(interpretation_classes, "confusion_class_rates_sensitivity.csv")

plot_labels <- c(categories$class_name, "background")
plot_data <- matrix_519 |>
  filter(gt_name %in% plot_labels, pred_name %in% plot_labels) |>
  mutate(
    pred_name = factor(pred_name, levels = plot_labels),
    gt_name = factor(gt_name, levels = rev(plot_labels))
  )

p_conf <- ggplot(plot_data, aes(x = pred_name, y = gt_name, fill = pct)) +
  geom_tile() +
  scale_fill_viridis_c(name = "%", limits = c(0, 100)) +
  coord_fixed() +
  theme_minimal(base_size = 8) +
  theme(
    axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5),
    panel.grid = element_blank()
  ) +
  labs(
    x = "Prediction",
    y = "Ground-truth class",
    title = "Sensitivity confusion matrix normalized by ground-truth class",
    subtitle = "519-image cleaned test set; score >= 0.50 in saved predictions; IoU >= 0.50"
  )

ggsave(
  "confusion_matrix_519_sensitivity.png",
  p_conf,
  width = 16,
  height = 16,
  units = "in",
  dpi = 220,
  bg = "white"
)

embedding_columns <- setdiff(names(embeddings_519), "file_name")
E_519 <- as.matrix(embeddings_519[, embedding_columns])
set.seed(42)
umap_519 <- uwot::umap(
  E_519,
  n_neighbors = 15,
  min_dist = 0.1,
  metric = "cosine"
)

vector_519 <- embeddings_519 |>
  select(file_name) |>
  mutate(UMAP1 = umap_519[, 1], UMAP2 = umap_519[, 2]) |>
  left_join(metrics_519, by = "file_name")

stopifnot(nrow(vector_519) == 519L, !anyDuplicated(vector_519$file_name))
write_csv(vector_519, "vector_analysis_519_sensitivity.csv")

p_f1 <- ggplot(vector_519, aes(UMAP1, UMAP2, color = F1)) +
  geom_point(size = 2.2, alpha = 0.9) +
  scale_color_viridis_c(option = "plasma", limits = c(0, 1), na.value = "grey80") +
  coord_equal() +
  theme_minimal(base_size = 13) +
  labs(
    title = "Sensitivity vector analysis: detection performance",
    subtitle = "519-image cleaned test set; color indicates per-image F1",
    color = "F1 score",
    x = NULL,
    y = NULL
  )

p_fn <- ggplot(vector_519, aes(UMAP1, UMAP2, color = FN_rate)) +
  geom_point(size = 2.2, alpha = 0.9) +
  scale_color_viridis_c(option = "inferno", limits = c(0, 1), na.value = "grey80") +
  coord_equal() +
  theme_minimal(base_size = 13) +
  labs(
    title = "Sensitivity vector analysis: detectability",
    subtitle = "519-image cleaned test set; color indicates per-image false-negative rate",
    color = "FN rate",
    x = NULL,
    y = NULL
  )

ggsave("F1-score_Vector_analysis_519_sensitivity.png", p_f1, width = 10, height = 8, units = "in", dpi = 300, bg = "white")
ggsave("FN-rate_Vector_analysis_519_sensitivity.png", p_fn, width = 10, height = 8, units = "in", dpi = 300, bg = "white")

knn_cosine <- function(X, k) {
  norms <- sqrt(rowSums(X^2))
  if (any(norms == 0)) stop("Zero-length embedding encountered")
  Xn <- X / norms
  sim <- Xn %*% t(Xn)
  diag(sim) <- -Inf
  t(apply(sim, 1, function(x) order(x, decreasing = TRUE)[seq_len(k)]))
}

knn_euclidean <- function(X, k) {
  d <- as.matrix(dist(X))
  diag(d) <- Inf
  t(apply(d, 1, function(x) order(x, decreasing = FALSE)[seq_len(k)]))
}

neighbor_enrichment <- function(X, group, eligible, analysis_name, group_name, space_name, k = 15L, permutations = 999L, seed = 42L) {
  X_sub <- X[eligible, , drop = FALSE]
  group_sub <- as.logical(group[eligible])
  n <- length(group_sub)
  n_group <- sum(group_sub)
  if (n_group < 2L || n_group >= n || n <= k) {
    return(tibble(
      analysis = analysis_name, group = group_name, space = space_name,
      eligible_images = n, group_images = n_group, prevalence = n_group / n,
      k = k, observed_same_group_neighbor_fraction = NA_real_,
      random_expectation = NA_real_, enrichment_ratio = NA_real_,
      permutation_p_upper = NA_real_
    ))
  }
  nn <- if (space_name == "CLIP_cosine") knn_cosine(X_sub, k) else knn_euclidean(X_sub, k)
  local_fraction <- function(labels) {
    idx <- which(labels)
    mean(vapply(idx, function(i) mean(labels[nn[i, ]]), numeric(1)))
  }
  observed <- local_fraction(group_sub)
  expectation <- (n_group - 1) / (n - 1)
  set.seed(seed)
  permuted <- replicate(permutations, local_fraction(sample(group_sub, replace = FALSE)))
  p_upper <- (1 + sum(permuted >= observed)) / (permutations + 1)
  tibble(
    analysis = analysis_name, group = group_name, space = space_name,
    eligible_images = n, group_images = n_group, prevalence = n_group / n,
    k = k, observed_same_group_neighbor_fraction = observed,
    random_expectation = expectation, enrichment_ratio = observed / expectation,
    permutation_p_upper = p_upper
  )
}

E_520 <- as.matrix(embeddings_520[, embedding_columns])
umap_520 <- as.matrix(vector_520[, c("UMAP1", "UMAP2")])
umap_519_matrix <- as.matrix(vector_519[, c("UMAP1", "UMAP2")])

analysis_sets <- list(
  list(name = "corrected_520", metrics = metrics_520, E = E_520, U = umap_520),
  list(name = "cleaned_519", metrics = metrics_519, E = E_519, U = umap_519_matrix)
)

neighborhood_results <- vector("list", 0L)
for (item in analysis_sets) {
  low_f1 <- !is.na(item$metrics$F1) & item$metrics$F1 <= 0.25
  high_fn <- !is.na(item$metrics$FN_rate) & item$metrics$FN_rate >= 0.75
  eligible_f1 <- !is.na(item$metrics$F1)
  eligible_fn <- !is.na(item$metrics$FN_rate)
  for (space_name in c("CLIP_cosine", "UMAP_euclidean")) {
    X_space <- if (space_name == "CLIP_cosine") item$E else item$U
    neighborhood_results[[length(neighborhood_results) + 1L]] <- neighbor_enrichment(
      X_space, low_f1, eligible_f1, item$name, "F1_le_0.25", space_name
    )
    neighborhood_results[[length(neighborhood_results) + 1L]] <- neighbor_enrichment(
      X_space, high_fn, eligible_fn, item$name, "FN_rate_ge_0.75", space_name
    )
  }
}

neighborhood_results <- bind_rows(neighborhood_results)
write_csv(neighborhood_results, "neighborhood_enrichment_sensitivity.csv")

diagnostic_summary <- tibble(
  removed_image = target_image,
  removed_image_TP = metrics_520$TP[metrics_520$file_name == target_image],
  removed_image_FP = metrics_520$FP[metrics_520$file_name == target_image],
  removed_image_FN = metrics_520$FN[metrics_520$file_name == target_image],
  removed_image_F1 = metrics_520$F1[metrics_520$file_name == target_image],
  removed_image_FN_rate = metrics_520$FN_rate[metrics_520$file_name == target_image],
  low_F1_images_520 = sum(metrics_520$F1 <= 0.25, na.rm = TRUE),
  low_F1_images_519 = sum(metrics_519$F1 <= 0.25, na.rm = TRUE),
  high_FN_images_520 = sum(metrics_520$FN_rate >= 0.75, na.rm = TRUE),
  high_FN_images_519 = sum(metrics_519$FN_rate >= 0.75, na.rm = TRUE),
  all_519_enrichment_p_values_non_significant = all(neighborhood_results$permutation_p_upper > 0.05, na.rm = TRUE)
)
write_csv(diagnostic_summary, "sensitivity_diagnostic_summary.csv")

message("Sensitivity diagnostics complete: 520-image and 519-image outputs written.")
