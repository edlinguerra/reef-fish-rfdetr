#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Evaluación de modelos de detección en formato COCO.

Entrada:
  - Ground truth COCO: _annotations.coco.json
  - Predicciones COCO results: predictions.json

Salida:
  - metrics_*.json
  - per_class_metrics_*.csv
  - confusion_matrix_*.csv

Ejemplo:
python scripts/evaluate_coco_predictions.py \
  --gt-json /ruta/bajo_10/dataset/valid/_annotations.coco.json \
  --pred-json outputs/valid/predictions_valid.json \
  --out-dir outputs/valid \
  --split valid \
  --iou-thr 0.50 \
  --conf-thr 0.25
"""

import argparse
import contextlib
import io
import json
from pathlib import Path

import numpy as np
import pandas as pd
from pycocotools.coco import COCO
from pycocotools.cocoeval import COCOeval


def bbox_iou_coco(box_a, box_b):
    """
    Calcula IoU entre dos cajas en formato COCO:
    [x, y, width, height]
    """

    ax1, ay1, aw, ah = box_a
    bx1, by1, bw, bh = box_b

    ax2 = ax1 + aw
    ay2 = ay1 + ah
    bx2 = bx1 + bw
    by2 = by1 + bh

    inter_x1 = max(ax1, bx1)
    inter_y1 = max(ay1, by1)
    inter_x2 = min(ax2, bx2)
    inter_y2 = min(ay2, by2)

    inter_w = max(0.0, inter_x2 - inter_x1)
    inter_h = max(0.0, inter_y2 - inter_y1)
    inter_area = inter_w * inter_h

    area_a = max(0.0, aw) * max(0.0, ah)
    area_b = max(0.0, bw) * max(0.0, bh)

    union = area_a + area_b - inter_area

    if union <= 0:
        return 0.0

    return inter_area / union


def run_coco_eval(gt_json, pred_json):
    """
    Ejecuta COCOeval para obtener mAP@50:95, mAP@50, mAP@75 y recall.
    """

    coco_gt = COCO(str(gt_json))

    with open(pred_json, "r", encoding="utf-8") as f:
        predictions = json.load(f)

    if len(predictions) == 0:
        raise ValueError(
            "El archivo de predicciones está vacío. "
            "No se puede ejecutar COCOeval sin detecciones."
        )

    coco_dt = coco_gt.loadRes(str(pred_json))

    evaluator = COCOeval(coco_gt, coco_dt, iouType="bbox")
    evaluator.evaluate()
    evaluator.accumulate()
    evaluator.summarize()

    metrics = {
        "mAP_50_95": float(evaluator.stats[0]),
        "mAP_50": float(evaluator.stats[1]),
        "mAP_75": float(evaluator.stats[2]),
        "mAP_50_95_small": float(evaluator.stats[3]),
        "mAP_50_95_medium": float(evaluator.stats[4]),
        "mAP_50_95_large": float(evaluator.stats[5]),
        "AR_1": float(evaluator.stats[6]),
        "AR_10": float(evaluator.stats[7]),
        "AR_100": float(evaluator.stats[8]),
        "AR_100_small": float(evaluator.stats[9]),
        "AR_100_medium": float(evaluator.stats[10]),
        "AR_100_large": float(evaluator.stats[11]),
    }

    return metrics


def category_ap50(gt_json, pred_json, cat_ids):
    """
    Calcula AP@50 por clase usando COCOeval.

    Se silencia la salida de COCOeval para no llenar la terminal.
    """

    coco_gt = COCO(str(gt_json))
    coco_dt = coco_gt.loadRes(str(pred_json))

    ap50_by_cat = {}

    for cat_id in cat_ids:
        evaluator = COCOeval(coco_gt, coco_dt, iouType="bbox")
        evaluator.params.catIds = [cat_id]

        with contextlib.redirect_stdout(io.StringIO()):
            evaluator.evaluate()
            evaluator.accumulate()
            evaluator.summarize()

        ap50_by_cat[cat_id] = float(evaluator.stats[1])

    return ap50_by_cat


def load_ground_truth(coco_gt):
    """
    Extrae anotaciones reales organizadas por imagen.
    """

    gt_by_image = {}

    for ann in coco_gt.dataset["annotations"]:
        image_id = ann["image_id"]

        gt_by_image.setdefault(image_id, []).append(
            {
                "annotation_id": ann.get("id"),
                "category_id": ann["category_id"],
                "bbox": ann["bbox"],
                "matched": False,
            }
        )

    return gt_by_image


def load_predictions(pred_json, conf_thr):
    """
    Carga predicciones filtradas por confianza y organizadas por imagen.
    """

    with open(pred_json, "r", encoding="utf-8") as f:
        predictions = json.load(f)

    pred_by_image = {}

    for pred in predictions:
        if pred["score"] < conf_thr:
            continue

        image_id = pred["image_id"]

        pred_by_image.setdefault(image_id, []).append(
            {
                "category_id": pred["category_id"],
                "bbox": pred["bbox"],
                "score": pred["score"],
            }
        )

    for image_id in pred_by_image:
        pred_by_image[image_id] = sorted(
            pred_by_image[image_id],
            key=lambda x: x["score"],
            reverse=True,
        )

    return pred_by_image


def compute_confusion_and_counts(coco_gt, pred_json, iou_thr=0.50, conf_thr=0.25):
    """
    Construye una matriz de confusión para detección de objetos.

    Reglas:
      - Se filtran predicciones por confidence threshold.
      - Se empareja cada predicción con la caja real no usada de mayor IoU.
      - Si IoU >= iou_thr:
          real vs predicho entra a la matriz.
          si clase real == clase predicha: TP
          si clase real != clase predicha: FP para clase predicha y FN para clase real
      - Si no hay match: FP contra background.
      - Si una caja real queda sin match: FN contra background.
    """

    categories = sorted(coco_gt.dataset["categories"], key=lambda x: x["id"])
    cat_ids = [cat["id"] for cat in categories]
    cat_names = {cat["id"]: cat["name"] for cat in categories}

    background_id = "__background__"

    labels = cat_ids + [background_id]

    confusion = pd.DataFrame(
        data=0,
        index=[cat_names.get(x, x) for x in labels],
        columns=[cat_names.get(x, x) for x in labels],
    )

    counts = {
        cat_id: {
            "class_id": cat_id,
            "class_name": cat_names[cat_id],
            "gt_count": 0,
            "pred_count": 0,
            "tp": 0,
            "fp": 0,
            "fn": 0,
        }
        for cat_id in cat_ids
    }

    gt_by_image = load_ground_truth(coco_gt)
    pred_by_image = load_predictions(pred_json, conf_thr)

    image_ids = sorted(coco_gt.getImgIds())

    for image_id in image_ids:
        gt_items = gt_by_image.get(image_id, [])
        pred_items = pred_by_image.get(image_id, [])

        for gt in gt_items:
            counts[gt["category_id"]]["gt_count"] += 1

        for pred in pred_items:
            counts[pred["category_id"]]["pred_count"] += 1

        for pred in pred_items:
            best_iou = 0.0
            best_gt_idx = None

            for idx, gt in enumerate(gt_items):
                if gt["matched"]:
                    continue

                iou = bbox_iou_coco(pred["bbox"], gt["bbox"])

                if iou > best_iou:
                    best_iou = iou
                    best_gt_idx = idx

            pred_cat = pred["category_id"]
            pred_name = cat_names[pred_cat]

            if best_gt_idx is not None and best_iou >= iou_thr:
                gt = gt_items[best_gt_idx]
                gt["matched"] = True

                gt_cat = gt["category_id"]
                gt_name = cat_names[gt_cat]

                confusion.loc[gt_name, pred_name] += 1

                if gt_cat == pred_cat:
                    counts[gt_cat]["tp"] += 1
                else:
                    counts[pred_cat]["fp"] += 1
                    counts[gt_cat]["fn"] += 1

            else:
                confusion.loc[background_id, pred_name] += 1
                counts[pred_cat]["fp"] += 1

        for gt in gt_items:
            if not gt["matched"]:
                gt_cat = gt["category_id"]
                gt_name = cat_names[gt_cat]

                confusion.loc[gt_name, background_id] += 1
                counts[gt_cat]["fn"] += 1

    rows = []

    total_tp = 0
    total_fp = 0
    total_fn = 0

    for cat_id, item in counts.items():
        tp = item["tp"]
        fp = item["fp"]
        fn = item["fn"]

        precision = tp / (tp + fp) if (tp + fp) > 0 else 0.0
        recall = tp / (tp + fn) if (tp + fn) > 0 else 0.0
        f1 = (
            2 * precision * recall / (precision + recall)
            if (precision + recall) > 0
            else 0.0
        )

        rows.append(
            {
                **item,
                "precision": precision,
                "recall": recall,
                "f1": f1,
            }
        )

        total_tp += tp
        total_fp += fp
        total_fn += fn

    overall_precision = (
        total_tp / (total_tp + total_fp)
        if (total_tp + total_fp) > 0
        else 0.0
    )

    overall_recall = (
        total_tp / (total_tp + total_fn)
        if (total_tp + total_fn) > 0
        else 0.0
    )

    overall_f1 = (
        2 * overall_precision * overall_recall / (overall_precision + overall_recall)
        if (overall_precision + overall_recall) > 0
        else 0.0
    )

    per_class = pd.DataFrame(rows)

    overall = {
        "iou_threshold_for_precision_recall": iou_thr,
        "confidence_threshold": conf_thr,
        "tp": int(total_tp),
        "fp": int(total_fp),
        "fn": int(total_fn),
        "precision": float(overall_precision),
        "recall": float(overall_recall),
        "f1": float(overall_f1),
    }

    return confusion, per_class, overall


def main():
    parser = argparse.ArgumentParser(
        description="Evaluación COCO para modelos de detección."
    )

    parser.add_argument(
        "--gt-json",
        required=True,
        type=Path,
        help="Ruta al archivo _annotations.coco.json del split evaluado.",
    )

    parser.add_argument(
        "--pred-json",
        required=True,
        type=Path,
        help="Ruta al archivo de predicciones en formato COCO results.",
    )

    parser.add_argument(
        "--out-dir",
        required=True,
        type=Path,
        help="Directorio donde se guardarán los resultados.",
    )

    parser.add_argument(
        "--split",
        default="valid",
        help="Nombre del split evaluado: valid, test o train.",
    )

    parser.add_argument(
        "--iou-thr",
        default=0.50,
        type=float,
        help="Umbral de IoU para precision, recall, F1 y matriz de confusión.",
    )

    parser.add_argument(
        "--conf-thr",
        default=0.25,
        type=float,
        help="Umbral de confianza para precision, recall, F1 y matriz de confusión.",
    )

    args = parser.parse_args()

    args.out_dir.mkdir(parents=True, exist_ok=True)

    if not args.gt_json.exists():
        raise FileNotFoundError(f"No existe el ground truth: {args.gt_json}")

    if not args.pred_json.exists():
        raise FileNotFoundError(f"No existe el archivo de predicciones: {args.pred_json}")

    print("\nCargando ground truth COCO...")
    coco_gt = COCO(str(args.gt_json))

    print("\nEjecutando COCOeval...")
    coco_metrics = run_coco_eval(args.gt_json, args.pred_json)

    print("\nCalculando matriz de confusión y métricas por clase...")
    confusion, per_class, pr_metrics = compute_confusion_and_counts(
        coco_gt=coco_gt,
        pred_json=args.pred_json,
        iou_thr=args.iou_thr,
        conf_thr=args.conf_thr,
    )

    cat_ids = sorted(coco_gt.getCatIds())
    ap50_by_cat = category_ap50(args.gt_json, args.pred_json, cat_ids)

    per_class["AP50"] = per_class["class_id"].map(ap50_by_cat)

    metrics = {
        "split": args.split,
        "gt_json": str(args.gt_json),
        "pred_json": str(args.pred_json),
        **coco_metrics,
        **pr_metrics,
    }

    metrics_path = args.out_dir / f"metrics_{args.split}.json"
    per_class_path = args.out_dir / f"per_class_metrics_{args.split}.csv"
    confusion_path = args.out_dir / f"confusion_matrix_{args.split}.csv"

    with open(metrics_path, "w", encoding="utf-8") as f:
        json.dump(metrics, f, indent=2, ensure_ascii=False)

    per_class.to_csv(per_class_path, index=False)
    confusion.to_csv(confusion_path)

    print("\nEvaluación terminada.")
    print(f"Métricas generales: {metrics_path}")
    print(f"Métricas por clase: {per_class_path}")
    print(f"Matriz de confusión: {confusion_path}")

    print("\nResumen:")
    print(f"mAP@50:95 = {metrics['mAP_50_95']:.4f}")
    print(f"mAP@50    = {metrics['mAP_50']:.4f}")
    print(f"Precision = {metrics['precision']:.4f}")
    print(f"Recall    = {metrics['recall']:.4f}")
    print(f"F1        = {metrics['f1']:.4f}")


if __name__ == "__main__":
    print("Entrando al script de evaluación...")
    main()