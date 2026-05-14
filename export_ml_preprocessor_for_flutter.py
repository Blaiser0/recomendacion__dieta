"""
Exporta JSON con el preprocesador (mismo split y fit que entrenamiento_modelo_metabolico.py)
para replicar en Flutter el vector de entrada del .tflite.

Ejecutar desde la raíz del proyecto:
  python export_ml_preprocessor_for_flutter.py
"""

from __future__ import annotations

import json
from pathlib import Path

import pandas as pd
from sklearn.compose import ColumnTransformer
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder, OneHotEncoder, StandardScaler

CSV_PATH = "Dataset_Obesidad_Espanol.csv"
TARGET_CANDIDATES = ("Nivel_Obesidad", "NObeyesdad")
OUT_JSON = Path("assets") / "ml_preprocessor.json"

df = pd.read_csv(CSV_PATH, encoding="utf-8")
TARGET_COL = next((c for c in TARGET_CANDIDATES if c in df.columns), None)
if TARGET_COL is None:
    raise SystemExit(f"No se encontró columna objetivo entre {TARGET_CANDIDATES}")

X = df.drop(columns=[TARGET_COL])
y = df[TARGET_COL]

X_train, _, y_train, _ = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)

label_encoder = LabelEncoder()
label_encoder.fit(y_train)

numeric_features = X_train.select_dtypes(include=["number"]).columns.tolist()
categorical_features = X_train.select_dtypes(include=["object", "category"]).columns.tolist()

preprocessor = ColumnTransformer(
    transformers=[
        ("num", StandardScaler(), numeric_features),
        (
            "cat",
            OneHotEncoder(handle_unknown="ignore", sparse_output=False),
            categorical_features,
        ),
    ],
    remainder="drop",
)
preprocessor.fit(X_train)

scaler: StandardScaler = preprocessor.named_transformers_["num"]
ohe: OneHotEncoder = preprocessor.named_transformers_["cat"]

config = {
    "numeric_features": numeric_features,
    "numeric_means": scaler.mean_.tolist(),
    "numeric_scales": scaler.scale_.tolist(),
    "categorical_features": categorical_features,
    "categorical_categories": [list(c) for c in ohe.categories_],
    "label_classes": label_encoder.classes_.tolist(),
    "input_size": int(preprocessor.transform(X_train.head(1)).shape[1]),
}

OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
OUT_JSON.write_text(json.dumps(config, ensure_ascii=False, indent=2), encoding="utf-8")
print(f"Escrito {OUT_JSON} (input_size={config['input_size']})")
