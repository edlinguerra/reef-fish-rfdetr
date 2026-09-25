#!/usr/bin/env python3
"""Integrity checks for the curated public package; standard library only."""
from __future__ import annotations

import csv
import json
import math
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def rows(relative: str) -> list[dict[str, str]]:
    with (ROOT / relative).open(newline="", encoding="utf-8-sig") as handle:
        return list(csv.DictReader(handle))


def close(actual: float, expected: float, tolerance: float = 1e-12) -> None:
    assert math.isclose(actual, expected, rel_tol=0.0, abs_tol=tolerance), (actual, expected)


def main() -> None:
    ontology = rows("config/class_ontology.csv")
    assert len(ontology) == 52
    assert {int(item["category_id"]) for item in ontology} == set(range(1, 53))
    assert sum(item["operational_class"] == "unidentifiable" for item in ontology) == 1

    accounting = {item["quantity"]: int(item["value"]) for item in rows("data/derived/dataset/dataset_accounting.csv")}
    assert accounting["training_source_images"] == 8517
    assert accounting["validation_images"] == 698
    assert accounting["test_images"] == 520
    assert accounting["total_preaugmentation_images"] == 9735
    assert accounting["exported_training_files"] == 4 * accounting["training_source_images"] == 34068
    assert accounting["training_samp_source_images"] == 6502
    assert accounting["training_inaturalist_source_images"] == 2015

    source = rows("data/derived/dataset/dataset_source_summary.csv")
    assert {item["source"] for item in source} == {"SAMP", "iNaturalist"}
    assert sum(int(item["preaugmentation_source_images"]) for item in source if item["split"] == "train") == 8517
    support = rows("data/derived/dataset/fig02_class_support.csv")
    assert len(support) == 52
    assert all(int(item["training_support"]) == int(item["SAMP_training_support"]) + int(item["iNaturalist_training_support"]) for item in support)

    selection = rows("data/derived/evaluation/fig03_validation_metrics.csv")
    assert len(selection) == 10
    assert [int(item["epoch_index"]) for item in selection] == list(range(10))
    selected = max(selection, key=lambda item: float(item["ema_ap50_95"]))
    assert int(selected["epoch_index"]) == 4
    close(float(selected["ema_ap50_95"]), 0.5255759074475391)

    table = rows("data/derived/evaluation/table01_test_performance.csv")
    assert len(table) == 1 and int(table[0]["test_images"]) == 520 and int(table[0]["gt_objects"]) == 1846
    close(float(table[0]["mAP@50"]), 0.7407811330935539)
    close(float(table[0]["mAP@50:95"]), 0.5448539544850933)
    close(float(table[0]["precision"]), 0.7944608346421937)
    close(float(table[0]["recall"]), 0.65)

    with (ROOT / "data/derived/evaluation/test_ground_truth.coco.json").open(encoding="utf-8") as handle:
        ground_truth = json.load(handle)
    assert len(ground_truth["images"]) == 520
    assert len(ground_truth["annotations"]) == 1846
    assert len(ground_truth["categories"]) == 53

    matrix = rows("figures/data/fig04_confusion_matrix.csv")
    outcomes = rows("figures/data/fig04_gt_outcomes.csv")
    assert len(matrix) == 52 * 53
    assert [int(item["count"]) for item in outcomes] == [1237, 112, 497]
    assert sum(int(item["count"]) for item in outcomes) == 1846

    image_metrics = rows("data/derived/diagnostics/per_image_metrics_corrected.csv")
    assert len(image_metrics) == 520
    assert sum(int(item["ground_truth_objects"]) > 0 for item in image_metrics) == 490
    assert sum(int(item["ground_truth_objects"]) == 0 for item in image_metrics) == 30
    assert sum(int(item["predicted_objects"]) == 0 for item in image_metrics) == 59
    assert sum(item["F1"] not in ("", "NA") and float(item["F1"]) == 0 for item in image_metrics) == 83
    assert sum(item["FN_rate"] not in ("", "NA") and float(item["FN_rate"]) >= 0.75 for item in image_metrics) == 95

    neighborhoods = [item for item in rows("data/derived/diagnostics/neighborhood_enrichment_corrected.csv") if item["analysis"] == "corrected"]
    assert len(neighborhoods) == 4 and {int(item["k"]) for item in neighborhoods} == {15}
    expected = {
        ("F1_le_0.25", "CLIP_cosine"): (0.9723479282985601, 0.588),
        ("F1_le_0.25", "UMAP_euclidean"): (0.9004995592124597, 0.895),
        ("FN_rate_ge_0.75", "CLIP_cosine"): (0.9528107502799552, 0.702),
        ("FN_rate_ge_0.75", "UMAP_euclidean"): (0.9272564389697648, 0.869),
    }
    for item in neighborhoods:
        ratio, p_value = expected[(item["group"], item["space"])]
        close(float(item["enrichment_ratio"]), ratio)
        close(float(item["permutation_p_upper"]), p_value)

    sensitivity = rows("data/derived/sensitivity/sensitivity_metric_comparison.csv")
    difference = next(item for item in sensitivity if item["analysis"] == "paired_difference_519_minus_520")
    paired_fields = ["mAP50_available_evaluator", "mAP50_95_available_evaluator", "best_precision_macro", "best_recall_macro", "best_F1_macro", "at_0_5_precision_macro", "at_0_5_recall_macro", "at_0_5_F1_macro"]
    assert max(abs(float(difference[field])) for field in paired_fields) < 0.00023

    archive = {item["measure"]: int(item["value"]) for item in rows("figures/data/archive_scale_summary.csv")}
    assert archive == {"image_records": 198965, "saved_detections": 81601}

    provenance = rows("metadata/inaturalist_provenance_manifest.csv")
    status = Counter(item["provenance_status"] for item in provenance)
    assert status["URL_RECOVERED"] == 2372
    assert status["AMBIGUOUS_MATCH"] == 319
    assert status["URL_MISSING"] == 2
    assert status["NOT_IN_FINAL_DATASET"] == 448
    close(2372 / 2693, 0.88080207946528, 1e-12)

    forbidden = {".jpg", ".jpeg", ".png", ".tif", ".tiff", ".webp", ".pth", ".pt", ".ckpt", ".zip"}
    found = [path for path in ROOT.rglob("*") if path.is_file() and path.suffix.lower() in forbidden]
    assert not found, f"Forbidden image/model/archive files: {found}"
    print("PASS: public-package scientific and release-integrity checks completed.")


if __name__ == "__main__":
    main()
