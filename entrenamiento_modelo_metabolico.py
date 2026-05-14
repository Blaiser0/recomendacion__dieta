"""
Entrenamiento de MLP (Keras) para clasificación metabólica (Nivel_Obesidad).
Requisitos: pip install tensorflow pandas scikit-learn numpy matplotlib
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd
import tensorflow as tf
from sklearn.compose import ColumnTransformer
from sklearn.metrics import ConfusionMatrixDisplay, confusion_matrix
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder, OneHotEncoder, StandardScaler

# ---------------------------------------------------------------------------
# 1) Carga de datos: separar X (16 variables) e y (Nivel_Obesidad / NObeyesdad)
# ---------------------------------------------------------------------------
CSV_PATH = "Dataset_Obesidad_Espanol.csv"
# Nombre de salida en UCI: NObeyesdad; en Dataset_Obesidad_Espanol.csv suele ser Nivel_Obesidad.
TARGET_CANDIDATES = ("Nivel_Obesidad", "NObeyesdad")

df = pd.read_csv(CSV_PATH, encoding="utf-8")
TARGET_COL = next((c for c in TARGET_CANDIDATES if c in df.columns), None)
if TARGET_COL is None:
    raise ValueError(
        "No se encontró la columna objetivo. Pruebe con una de: "
        f"{TARGET_CANDIDATES}. Columnas leídas: {list(df.columns)}"
    )

X = df.drop(columns=[TARGET_COL])
y = df[TARGET_COL]

# ---------------------------------------------------------------------------
# 2) División 80/20 (stratify) y exportación CRUDA del conjunto de test
# ---------------------------------------------------------------------------
X_train, X_test, y_train, y_test = train_test_split(
    X,
    y,
    test_size=0.2,
    random_state=42,
    stratify=y,
)

test_crudo = pd.concat([X_test, y_test], axis=1)
path_test = Path("datos_test_para_app_20.csv")

def _frames_test_iguales(a: pd.DataFrame, b: pd.DataFrame) -> None:
    cols = a.columns.tolist()
    e = a[cols].sort_values(by=cols).reset_index(drop=True)
    o = b[cols].sort_values(by=cols).reset_index(drop=True)
    pd.testing.assert_frame_equal(o, e, check_dtype=False, rtol=1e-5, atol=1e-5)


if path_test.exists():
    _disk = pd.read_csv(path_test, encoding="utf-8")
    _frames_test_iguales(test_crudo, _disk)
    print(
        "Verificación OK: datos_test_para_app_20.csv coincide con X_test|y_test "
        "crudos (sin preprocesamiento en el archivo)."
    )
    try:
        test_crudo.to_csv(path_test, index=False, encoding="utf-8")
    except PermissionError:
        print(
            "AVISO: no se pudo sobrescribir datos_test_para_app_20.csv (archivo "
            "bloqueado). El contenido en disco ya está verificado como split crudo."
        )
else:
    test_crudo.to_csv(path_test, index=False, encoding="utf-8")
    _exportado = pd.read_csv(path_test, encoding="utf-8")
    _frames_test_iguales(test_crudo, _exportado)
    print(
        "Verificación OK: datos_test_para_app_20.csv exportado; coincide con "
        "X_test|y_test crudos (sin preprocesamiento aplicado al archivo)."
    )

# ---------------------------------------------------------------------------
# 3) Preprocesamiento: LabelEncoder en y; StandardScaler + OneHotEncoder en X
#    (fit SOLO con train; transform en train y test)
# ---------------------------------------------------------------------------
label_encoder = LabelEncoder()
y_train_enc = label_encoder.fit_transform(y_train)
y_test_enc = label_encoder.transform(y_test)

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

X_train_proc = preprocessor.fit_transform(X_train)
X_test_proc = preprocessor.transform(X_test)

# ---------------------------------------------------------------------------
# 4) Red neuronal (MLP secuencial)
# ---------------------------------------------------------------------------
n_features = int(X_train_proc.shape[1])

model = tf.keras.Sequential(
    [
        tf.keras.layers.Input(shape=(n_features,)),
        tf.keras.layers.Dense(128, activation="relu"),
        tf.keras.layers.Dropout(0.2),
        tf.keras.layers.Dense(64, activation="relu"),
        tf.keras.layers.Dense(7, activation="softmax"),
    ]
)

# ---------------------------------------------------------------------------
# 5) Compilación y entrenamiento (validación = 20% preprocesado)
# ---------------------------------------------------------------------------
model.compile(
    optimizer="adam",
    loss="sparse_categorical_crossentropy",
    metrics=["accuracy"],
)

history = model.fit(
    X_train_proc,
    y_train_enc,
    validation_data=(X_test_proc, y_test_enc),
    epochs=50,
    batch_size=32,
    verbose=1,
)

# Métricas finales en test (opcional, para consola)
loss, acc = model.evaluate(X_test_proc, y_test_enc, verbose=0)
print(f"Test loss: {loss:.4f} | Test accuracy: {acc:.4f}")

# Matriz de confusión (conjunto de test, etiquetas ya codificadas con el mismo encoder)
y_proba = model.predict(X_test_proc, verbose=0)
y_pred_enc = np.argmax(y_proba, axis=1)
_etiquetas = list(label_encoder.classes_)
cm = confusion_matrix(
    y_test_enc,
    y_pred_enc,
    labels=list(range(len(_etiquetas))),
)
cm_df = pd.DataFrame(cm, index=_etiquetas, columns=_etiquetas)
cm_df.index.name = "verdadero"
cm_df.to_csv("matriz_confusion_test.csv", encoding="utf-8")
print("Escrito matriz_confusion_test.csv (filas=verdadero, columnas=predicho)")

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt

fig, ax = plt.subplots(figsize=(9, 7))
ConfusionMatrixDisplay(cm, display_labels=_etiquetas).plot(
    ax=ax,
    xticks_rotation=45,
    colorbar=False,
)
ax.set_title("Matriz de confusión — conjunto de test (20 %)")
plt.tight_layout()
plt.savefig("matriz_confusion_test.png", dpi=150)
plt.close()
print("Escrito matriz_confusion_test.png")

# ---------------------------------------------------------------------------
# 6) Exportación a TensorFlow Lite
# ---------------------------------------------------------------------------
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()
with open("modelo_diagnostico_metabolico.tflite", "wb") as f:
    f.write(tflite_model)

print("Archivos generados:")
print(" - datos_test_para_app_20.csv")
print(" - matriz_confusion_test.csv")
print(" - matriz_confusion_test.png")
print(" - modelo_diagnostico_metabolico.tflite")
print("Clases (orden LabelEncoder):", list(label_encoder.classes_))
