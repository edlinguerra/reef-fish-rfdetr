# Corrected full-test vector analysis
#
# This script is a non-destructive correction of vector_analysis.R. It uses all
# 520 test images, assigns false negatives to images with zero detections, treats
# class-confusion matches as both a species-level FP and FN, preserves the
# original score/IoU thresholds, and reruns UMAP with the original settings.

suppressPackageStartupMessages({
  library(jsonlite)
  library(dplyr)
  library(tidyr)
  library(purrr)
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
output_dir <- arg_value("--output-dir", "outputs/vector_analysis")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
setwd(output_dir)

gt <- fromJSON(file.path(evaluation_dir, "test_ground_truth.coco.json"), flatten = TRUE)
pred <- fromJSON(file.path(evaluation_dir, "test_predictions.coco.json"), flatten = TRUE)
emb <- read_csv(file.path(diagnostic_dir, "vector_analysis_embeddings.csv"), show_col_types = FALSE)

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

stopifnot(
  length(all_test_images) == 520L,
  nrow(emb) == 520L,
  ncol(emb) == 513L,
  !anyDuplicated(emb$file_name),
  setequal(emb$file_name, all_test_images)
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

  add_event <- function(file_name, gt_class, pred_class, event_type) {
    tibble(
      file_name = file_name,
      gt = as.character(gt_class),
      pred = as.character(pred_class),
      event_type = event_type
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
            img, gt_img$category_id[i], pr_img$category_id[j_best], event_type
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
      for (j in which(!used_pred)) {
        events[[length(events) + 1L]] <- add_event(
          img, "background", pr_img$category_id[j], "unmatched_prediction"
        )
      }
    }
  }

  bind_rows(events)
}

metrics_from_events <- function(events, image_names, corrected_definition = TRUE) {
  by_image <- events |>
    group_by(file_name) |>
    summarise(
      TP = sum(event_type == "correct_match"),
      class_confusions = sum(event_type == "class_confusion"),
      unmatched_FP = sum(event_type == "unmatched_prediction"),
      unmatched_FN = sum(event_type == "unmatched_ground_truth"),
      .groups = "drop"
    ) |>
    mutate(
      FP = unmatched_FP + if (corrected_definition) class_confusions else 0L,
      FN = unmatched_FN + if (corrected_definition) class_confusions else 0L
    )

  tibble(file_name = image_names) |>
    left_join(by_image, by = "file_name") |>
    mutate(
      across(
        c(TP, class_confusions, unmatched_FP, unmatched_FN, FP, FN),
        ~ replace_na(.x, 0L)
      ),
      ground_truth_objects = TP + FN,
      predicted_objects = TP + FP,
      precision = ifelse(predicted_objects > 0, TP / predicted_objects, NA_real_),
      recall = ifelse(ground_truth_objects > 0, TP / ground_truth_objects, NA_real_),
      F1 = case_when(
        ground_truth_objects > 0 & TP == 0 & FN > 0 ~ 0,
        !is.na(precision) & !is.na(recall) & (precision + recall) > 0 ~
          2 * precision * recall / (precision + recall),
        TRUE ~ NA_real_
      ),
      FN_rate = ifelse(ground_truth_objects > 0, FN / ground_truth_objects, NA_real_),
      metric_state = case_when(
        ground_truth_objects > 0 & TP == 0 & FN > 0 ~ "defined_zero_performance",
        ground_truth_objects > 0 ~ "defined",
        ground_truth_objects == 0 & predicted_objects > 0 ~ "recall_and_f1_undefined_no_ground_truth",
        TRUE ~ "precision_recall_f1_undefined_no_objects"
      )
    )
}

events_original <- build_events(original_effective_images, corrected_matching = FALSE)
events_corrected <- build_events(all_test_images, corrected_matching = TRUE)

# Exact original metric behavior: the effective 461-image event universe,
# confusion matches ignored in TP/FP/FN, followed by a join to all 520 images.
metrics_original <- metrics_from_events(
  events_original,
  all_test_images,
  corrected_definition = FALSE
)

# Restore the original script's NA behavior for images that never entered its
# event universe.
metrics_original <- metrics_original |>
  mutate(
    was_in_original_effective_universe = file_name %in% original_effective_images,
    precision = ifelse(was_in_original_effective_universe, precision, NA_real_),
    recall = ifelse(was_in_original_effective_universe, recall, NA_real_),
    F1 = ifelse(was_in_original_effective_universe, F1, NA_real_),
    FN_rate = ifelse(was_in_original_effective_universe, FN_rate, NA_real_),
    metric_state = ifelse(
      was_in_original_effective_universe,
      metric_state,
      "excluded_from_original_effective_universe"
    )
  )

metrics_corrected <- metrics_from_events(
  events_corrected,
  all_test_images,
  corrected_definition = TRUE
) |>
  mutate(was_in_original_effective_universe = file_name %in% original_effective_images)

stopifnot(
  nrow(metrics_corrected) == 520L,
  sum(!metrics_corrected$was_in_original_effective_universe) == 59L,
  all(
    metrics_corrected$F1[
      metrics_corrected$ground_truth_objects > 0 &
        metrics_corrected$TP == 0 & metrics_corrected$FN > 0
    ] == 0
  )
)

write_csv(metrics_original, "per_image_metrics_original_reconstructed.csv")
write_csv(metrics_corrected, "per_image_metrics_corrected.csv")

vec_corrected <- emb |>
  left_join(metrics_corrected, by = "file_name")

embedding_columns <- setdiff(
  names(emb),
  "file_name"
)
E <- as.matrix(vec_corrected[, embedding_columns])
storage.mode(E) <- "double"

# Same UMAP settings as the original analysis.
set.seed(42)
umap_res <- uwot::umap(
  E,
  n_neighbors = 15,
  min_dist = 0.1,
  metric = "cosine"
)

vec_corrected <- vec_corrected |>
  mutate(
    UMAP1 = umap_res[, 1],
    UMAP2 = umap_res[, 2]
  )

write_csv(vec_corrected, "vector_analysis_corrected.csv")

p_f1 <- ggplot(vec_corrected, aes(UMAP1, UMAP2, color = F1)) +
  geom_point(size = 2.2, alpha = 0.9) +
  scale_color_viridis_c(
    option = "magma",
    limits = c(0, 1),
    na.value = "grey80"
  ) +
  coord_equal() +
  theme_minimal(base_size = 13) +
  labs(
    title = "Corrected vector analysis (CLIP + UMAP)",
    subtitle = "All 520 test images; color indicates per-image species-level F1",
    color = "F1 score",
    x = NULL,
    y = NULL
  )

p_fn <- ggplot(vec_corrected, aes(UMAP1, UMAP2, color = FN_rate)) +
  geom_point(size = 2.2, alpha = 0.9) +
  scale_color_viridis_c(
    option = "inferno",
    limits = c(0, 1),
    na.value = "grey80"
  ) +
  coord_equal() +
  theme_minimal(base_size = 13) +
  labs(
    title = "Corrected vector analysis: detectability",
    subtitle = "All 520 test images; color indicates per-image false-negative rate",
    color = "FN rate",
    x = NULL,
    y = NULL
  )

ggsave(
  "F1-score_Vector_analysis_corrected.png",
  p_f1,
  width = 10,
  height = 8,
  units = "in",
  dpi = 300,
  bg = "white"
)
ggsave(
  "FN-rate_Vector_analysis_corrected.png",
  p_fn,
  width = 10,
  height = 8,
  units = "in",
  dpi = 300,
  bg = "white"
)

# Quantitative local-neighborhood check. Low F1 is defined a priori as <= 0.25;
# high false-negative rate is defined as >= 0.75. Enrichment is evaluated among
# the 15 nearest neighbors, matching the UMAP n_neighbors setting, in both the
# original CLIP space and the two-dimensional UMAP projection.
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

neighbor_enrichment <- function(
  X,
  group,
  eligible,
  analysis_name,
  group_name,
  space_name,
  k = 15L,
  permutations = 999L,
  seed = 42L
) {
  X_sub <- X[eligible, , drop = FALSE]
  group_sub <- as.logical(group[eligible])
  n <- length(group_sub)
  n_group <- sum(group_sub)

  if (n_group < 2L || n_group >= n || n <= k) {
    return(tibble(
      analysis = analysis_name,
      group = group_name,
      space = space_name,
      eligible_images = n,
      group_images = n_group,
      prevalence = n_group / n,
      k = k,
      observed_same_group_neighbor_fraction = NA_real_,
      random_expectation = NA_real_,
      enrichment_ratio = NA_real_,
      permutation_p_upper = NA_real_
    ))
  }

  nn <- if (space_name == "CLIP_cosine") {
    knn_cosine(X_sub, k)
  } else {
    knn_euclidean(X_sub, k)
  }

  local_fraction <- function(labels) {
    idx <- which(labels)
    mean(vapply(idx, function(i) mean(labels[nn[i, ]]), numeric(1)))
  }

  observed <- local_fraction(group_sub)
  expectation <- (n_group - 1) / (n - 1)

  set.seed(seed)
  permuted <- replicate(
    permutations,
    local_fraction(sample(group_sub, replace = FALSE))
  )
  p_upper <- (1 + sum(permuted >= observed)) / (permutations + 1)

  tibble(
    analysis = analysis_name,
    group = group_name,
    space = space_name,
    eligible_images = n,
    group_images = n_group,
    prevalence = n_group / n,
    k = k,
    observed_same_group_neighbor_fraction = observed,
    random_expectation = expectation,
    enrichment_ratio = observed / expectation,
    permutation_p_upper = p_upper
  )
}

umap_matrix <- as.matrix(vec_corrected[, c("UMAP1", "UMAP2")])

analysis_sets <- list(
  list(
    name = "original_reconstructed",
    metrics = metrics_original,
    eligible_f1 = !is.na(metrics_original$F1),
    eligible_fn = !is.na(metrics_original$FN_rate)
  ),
  list(
    name = "corrected",
    metrics = metrics_corrected,
    eligible_f1 = !is.na(metrics_corrected$F1),
    eligible_fn = !is.na(metrics_corrected$FN_rate)
  )
)

neighborhood_results <- vector("list", 0L)

for (item in analysis_sets) {
  low_f1 <- !is.na(item$metrics$F1) & item$metrics$F1 <= 0.25
  high_fn <- !is.na(item$metrics$FN_rate) & item$metrics$FN_rate >= 0.75

  for (space_name in c("CLIP_cosine", "UMAP_euclidean")) {
    X_space <- if (space_name == "CLIP_cosine") E else umap_matrix

    neighborhood_results[[length(neighborhood_results) + 1L]] <-
      neighbor_enrichment(
        X_space,
        low_f1,
        item$eligible_f1,
        item$name,
        "F1_le_0.25",
        space_name
      )

    neighborhood_results[[length(neighborhood_results) + 1L]] <-
      neighbor_enrichment(
        X_space,
        high_fn,
        item$eligible_fn,
        item$name,
        "FN_rate_ge_0.75",
        space_name
      )
  }
}

neighborhood_results <- bind_rows(neighborhood_results)
write_csv(neighborhood_results, "neighborhood_enrichment_corrected.csv")

metric_summary <- bind_rows(
  metrics_original |>
    summarise(
      analysis = "original_reconstructed",
      images_total = n(),
      images_with_defined_F1 = sum(!is.na(F1)),
      images_with_defined_FN_rate = sum(!is.na(FN_rate)),
      zero_performance_images = sum(F1 == 0, na.rm = TRUE),
      TP = sum(TP),
      FP = sum(FP),
      FN = sum(FN)
    ),
  metrics_corrected |>
    summarise(
      analysis = "corrected",
      images_total = n(),
      images_with_defined_F1 = sum(!is.na(F1)),
      images_with_defined_FN_rate = sum(!is.na(FN_rate)),
      zero_performance_images = sum(F1 == 0, na.rm = TRUE),
      TP = sum(TP),
      FP = sum(FP),
      FN = sum(FN)
    )
)

write_csv(metric_summary, "per_image_metric_summary_corrected.csv")

print(metric_summary)
print(neighborhood_results)
