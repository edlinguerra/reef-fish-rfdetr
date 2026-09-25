# Corrected full-test confusion-matrix analysis
#
# This script is a non-destructive correction of matriz_confusion.R. It:
#   * uses every image listed in _annotations.coco.json;
#   * retains images with zero detections;
#   * assigns every unmatched ground-truth object to background (false negative);
#   * keeps the original score threshold (0.25) and IoU threshold (0.50);
#   * fixes a one-to-one matching error by choosing the best UNUSED prediction.

suppressPackageStartupMessages({
  library(jsonlite)
  library(dplyr)
  library(tidyr)
  library(purrr)
  library(tibble)
  library(ggplot2)
  library(readr)
})

options(stringsAsFactors = FALSE)

args <- commandArgs(trailingOnly = TRUE)
arg_value <- function(flag, default) {
  hit <- grep(paste0("^", flag, "="), args, value = TRUE)
  if (length(hit) == 0L) default else sub(paste0("^", flag, "="), "", hit[[1]])
}
data_dir <- normalizePath(arg_value("--data-dir", "data/derived/evaluation"), mustWork = TRUE)
output_dir <- arg_value("--output-dir", "outputs/diagnostics")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
setwd(output_dir)

gt_path <- file.path(data_dir, "test_ground_truth.coco.json")
pred_path <- file.path(data_dir, "test_predictions.coco.json")

stopifnot(file.exists(gt_path), file.exists(pred_path))

gt <- fromJSON(gt_path, flatten = TRUE)
pred <- fromJSON(pred_path, flatten = TRUE)

categories <- gt$categories |>
  as_tibble() |>
  transmute(category_id = as.character(id), class_name = name)

gt_ann <- gt$annotations |>
  as_tibble() |>
  mutate(category_id = as.character(category_id)) |>
  left_join(
    gt$images |>
      as_tibble() |>
      transmute(image_id = id, file_name),
    by = "image_id"
  ) |>
  select(file_name, category_id, bbox)

# Preserved from the original analysis.
score_threshold <- 0.25
iou_threshold <- 0.50

pred_ann <- pred$annotations |>
  as_tibble() |>
  filter(score >= score_threshold) |>
  mutate(category_id = as.character(category_id)) |>
  left_join(
    pred$images |>
      as_tibble() |>
      transmute(image_id = id, file_name),
    by = "image_id"
  ) |>
  select(file_name, category_id, bbox, score)

all_test_images <- unique(gt$images$file_name)
images_with_detections <- unique(pred_ann$file_name)
original_effective_images <- intersect(all_test_images, images_with_detections)
restored_zero_detection_images <- setdiff(all_test_images, images_with_detections)

stopifnot(
  length(all_test_images) == 520L,
  all(images_with_detections %in% all_test_images)
)

iou <- function(a, b) {
  ax1 <- a[1]; ay1 <- a[2]
  ax2 <- a[1] + a[3]; ay2 <- a[2] + a[4]
  bx1 <- b[1]; by1 <- b[2]
  bx2 <- b[1] + b[3]; by2 <- b[2] + b[4]

  ix1 <- max(ax1, bx1)
  iy1 <- max(ay1, by1)
  ix2 <- min(ax2, bx2)
  iy2 <- min(ay2, by2)

  iw <- max(0, ix2 - ix1)
  ih <- max(0, iy2 - iy1)
  inter <- iw * ih
  union <- a[3] * a[4] + b[3] * b[4] - inter

  ifelse(union == 0, 0, inter / union)
}

build_events <- function(image_names, corrected_matching = TRUE) {
  events <- vector("list", 0L)

  add_event <- function(file_name, gt_class, pred_class, event_type, match_iou = NA_real_) {
    tibble(
      file_name = file_name,
      gt = as.character(gt_class),
      pred = as.character(pred_class),
      event_type = event_type,
      match_iou = match_iou
    )
  }

  for (img in image_names) {
    gt_img <- gt_ann |> filter(file_name == img)
    pr_img <- pred_ann |> filter(file_name == img)
    used_pred <- rep(FALSE, nrow(pr_img))

    if (nrow(gt_img) > 0L) {
      for (i in seq_len(nrow(gt_img))) {
        gt_box <- unlist(gt_img$bbox[i])

        if (nrow(pr_img) == 0L) {
          events[[length(events) + 1L]] <- add_event(
            img, gt_img$category_id[i], "background", "unmatched_ground_truth"
          )
          next
        }

        if (corrected_matching) {
          # Clear correction to the original implementation: once a prediction
          # has been used, select the best remaining prediction rather than
          # marking the GT as missed merely because the global best was used.
          candidate_idx <- which(!used_pred)
          if (length(candidate_idx) == 0L) {
            events[[length(events) + 1L]] <- add_event(
              img, gt_img$category_id[i], "background", "unmatched_ground_truth"
            )
            next
          }
          candidate_ious <- map_dbl(
            candidate_idx,
            ~ iou(gt_box, unlist(pr_img$bbox[.x]))
          )
          best_pos <- which.max(candidate_ious)
          j_best <- candidate_idx[best_pos]
          best_iou <- candidate_ious[best_pos]
        } else {
          # Exact behavior of the original script, retained only for comparison.
          candidate_ious <- map_dbl(
            seq_len(nrow(pr_img)),
            ~ iou(gt_box, unlist(pr_img$bbox[.x]))
          )
          j_best <- which.max(candidate_ious)
          best_iou <- candidate_ious[j_best]
        }

        if (best_iou >= iou_threshold && !used_pred[j_best]) {
          event_type <- if (
            as.character(gt_img$category_id[i]) == as.character(pr_img$category_id[j_best])
          ) "correct_match" else "class_confusion"

          events[[length(events) + 1L]] <- add_event(
            img,
            gt_img$category_id[i],
            pr_img$category_id[j_best],
            event_type,
            best_iou
          )
          used_pred[j_best] <- TRUE
        } else {
          events[[length(events) + 1L]] <- add_event(
            img, gt_img$category_id[i], "background", "unmatched_ground_truth"
          )
        }
      }
    }

    if (nrow(pr_img) > 0L) {
      unused_idx <- which(!used_pred)
      for (j in unused_idx) {
        events[[length(events) + 1L]] <- add_event(
          img, "background", pr_img$category_id[j], "unmatched_prediction"
        )
      }
    }
  }

  bind_rows(events)
}

summarize_events <- function(events, image_count, include_class_confusions = TRUE) {
  tp <- sum(events$event_type == "correct_match")
  class_confusions <- sum(events$event_type == "class_confusion")
  unmatched_fp <- sum(events$event_type == "unmatched_prediction")
  unmatched_fn <- sum(events$event_type == "unmatched_ground_truth")

  tibble(
    images = image_count,
    TP = tp,
    FP = unmatched_fp + ifelse(include_class_confusions, class_confusions, 0L),
    FN = unmatched_fn + ifelse(include_class_confusions, class_confusions, 0L),
    class_confusions = class_confusions,
    unmatched_predictions = unmatched_fp,
    unmatched_ground_truth = unmatched_fn
  )
}

# Reconstruct the original effective-universe result, then isolate the effect
# of restoring all images from the effect of correcting one-to-one matching.
events_original_effective <- build_events(
  original_effective_images,
  corrected_matching = FALSE
)
events_full_original_matching <- build_events(
  all_test_images,
  corrected_matching = FALSE
)
events_corrected <- build_events(
  all_test_images,
  corrected_matching = TRUE
)

# Integrity checks: every GT object and retained prediction must be represented
# exactly once in the corrected event table.
stopifnot(
  sum(events_corrected$gt != "background") == nrow(gt_ann),
  sum(events_corrected$pred != "background") == nrow(pred_ann),
  length(unique(all_test_images)) == 520L
)

comparison_summary <- bind_rows(
  summarize_events(
    events_original_effective,
    length(original_effective_images),
    include_class_confusions = FALSE
  ) |> mutate(analysis = "original_script_definition"),
  summarize_events(
    events_original_effective,
    length(original_effective_images),
    include_class_confusions = TRUE
  ) |> mutate(analysis = "original_effective_comparable_definition"),
  summarize_events(
    events_full_original_matching,
    length(all_test_images),
    include_class_confusions = TRUE
  ) |> mutate(analysis = "full_universe_original_matching"),
  summarize_events(
    events_corrected,
    length(all_test_images),
    include_class_confusions = TRUE
  ) |> mutate(analysis = "corrected_full_universe"
  )
) |>
  relocate(analysis)

restored_gt_count <- gt_ann |>
  filter(file_name %in% restored_zero_detection_images) |>
  nrow()

restoration_summary <- tibble(
  all_test_images = length(all_test_images),
  original_effective_images = length(original_effective_images),
  restored_zero_detection_images = length(restored_zero_detection_images),
  ground_truth_objects_in_restored_images = restored_gt_count,
  score_threshold = score_threshold,
  iou_threshold = iou_threshold
)

write_csv(events_corrected, "confusion_events_corrected.csv")
write_csv(comparison_summary, "diagnostic_comparison_summary.csv")
write_csv(restoration_summary, "diagnostic_restoration_summary.csv")
write_lines(restored_zero_detection_images, "restored_zero_detection_images.txt")

confusion_interpretation_metrics <- function(events, analysis_name) {
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
      analysis = analysis_name,
      ground_truth_objects = nrow(gt_events),
      correct_diagonal = sum(gt_events$gt == gt_events$pred),
      false_negative_background = sum(gt_events$pred == "background"),
      class_confusions = sum(
        gt_events$pred != "background" & gt_events$pred != gt_events$gt
      ),
      diagonal_fraction = mean(gt_events$gt == gt_events$pred),
      false_negative_background_fraction = mean(gt_events$pred == "background"),
      class_confusion_fraction = mean(
        gt_events$pred != "background" & gt_events$pred != gt_events$gt
      ),
      classes_with_ground_truth = nrow(per_class),
      classes_where_diagonal_is_largest = sum(per_class$diagonal_is_largest),
      median_class_diagonal_fraction = median(per_class$diagonal_fraction),
      mean_class_diagonal_fraction = mean(per_class$diagonal_fraction)
    ),
    per_class = per_class |>
      mutate(analysis = analysis_name) |>
      relocate(analysis)
  )
}

original_confusion_metrics <- confusion_interpretation_metrics(
  events_original_effective,
  "original_effective_universe"
)
corrected_confusion_metrics <- confusion_interpretation_metrics(
  events_corrected,
  "corrected_full_universe"
)

confusion_overall_comparison <- bind_rows(
  original_confusion_metrics$overall,
  corrected_confusion_metrics$overall
)
confusion_class_comparison <- bind_rows(
  original_confusion_metrics$per_class,
  corrected_confusion_metrics$per_class
)

class_rate_wide <- confusion_class_comparison |>
  select(analysis, gt, diagonal_fraction) |>
  pivot_wider(names_from = analysis, values_from = diagonal_fraction)

confusion_change_summary <- tibble(
  spearman_class_diagonal_fraction = cor(
    class_rate_wide$original_effective_universe,
    class_rate_wide$corrected_full_universe,
    method = "spearman",
    use = "complete.obs"
  ),
  mean_absolute_class_diagonal_change = mean(
    abs(
      class_rate_wide$corrected_full_universe -
        class_rate_wide$original_effective_universe
    ),
    na.rm = TRUE
  )
)

write_csv(
  confusion_overall_comparison,
  "confusion_interpretation_comparison.csv"
)
write_csv(
  confusion_class_comparison,
  "confusion_class_rates_comparison.csv"
)
write_csv(
  confusion_change_summary,
  "confusion_change_summary.csv"
)

labels <- c(categories$category_id, "background")

conf_counts <- events_corrected |>
  count(gt, pred, name = "n") |>
  complete(gt = labels, pred = labels, fill = list(n = 0L)) |>
  left_join(categories, by = c("gt" = "category_id")) |>
  rename(gt_name = class_name) |>
  left_join(categories, by = c("pred" = "category_id")) |>
  rename(pred_name = class_name) |>
  mutate(
    gt_name = ifelse(is.na(gt_name), gt, gt_name),
    pred_name = ifelse(is.na(pred_name), pred, pred_name)
  )

conf_norm <- conf_counts |>
  group_by(gt_name) |>
  mutate(
    row_total = sum(n),
    pct = ifelse(row_total > 0, 100 * n / row_total, 0)
  ) |>
  ungroup()

write_csv(conf_counts, "confusion_matrix_counts_corrected.csv")
write_csv(conf_norm, "confusion_matrix_normalized_corrected.csv")

plot_labels <- c(
  categories |> filter(class_name != "fish") |> pull(class_name),
  "background"
)

plot_data <- conf_norm |>
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
    title = "Corrected confusion matrix normalized by ground-truth class",
    subtitle = paste0(
      "All 520 test images; score threshold = ", score_threshold,
      "; IoU threshold = ", iou_threshold
    )
  )

ggsave(
  "confusion_matrix_corrected.png",
  p_conf,
  width = 16,
  height = 16,
  units = "in",
  dpi = 220,
  bg = "white"
)

print(restoration_summary)
print(comparison_summary)
print(confusion_overall_comparison)
print(confusion_change_summary)
