"""One repetition in, four form probabilities out. No training happens here."""

import json
from pathlib import Path

import joblib
import numpy as np
from tensorflow import keras

MODEL_DIR = Path(__file__).resolve().parents[1] / "ML" / "model_outputs"


def prepare_repetition(imu, emg):
    """Match train.py: centered 50-sample RMS, overlap, alignment, resampling."""
    imu = np.asarray(imu, dtype=np.float64)
    emg = np.asarray(emg, dtype=np.float64)
    for values, width, minimum in ((imu, 7, 2), (emg, 3, 50)):
        if values.ndim != 2 or values.shape[1] != width or len(values) < minimum:
            raise ValueError(f"Expected at least {minimum} rows with {width} values each.")
        if not np.isfinite(values).all():
            raise ValueError("All sensor values must be finite numbers.")
        if np.any(np.diff(values[:, 0]) <= 0):
            raise ValueError("Timestamps must be strictly increasing within each stream.")
    start = max(imu[0, 0], emg[0, 0])
    end = min(imu[-1, 0], emg[-1, 0])
    aligned = imu[(imu[:, 0] >= start) & (imu[:, 0] <= end)]
    if len(aligned) < 2:
        raise ValueError("Streams must share at least two IMU timestamps.")
    envelope = [
        np.sqrt(np.convolve(emg[:, column] ** 2, np.ones(50) / 50, mode="same"))
        for column in (1, 2)
    ]
    features = np.column_stack([
        aligned[:, 1:],
        *[np.interp(aligned[:, 0], emg[:, 0], signal) for signal in envelope],
    ])
    positions = np.linspace(0, 1, len(features))
    sequence = np.column_stack([
        np.interp(np.linspace(0, 1, 256), positions, features[:, column])
        for column in range(8)
    ]).astype(np.float32)
    if not np.isfinite(sequence).all():
        raise ValueError("Sensor values are too large to process.")
    return sequence


class FormPredictor:
    def __init__(self):
        self.metadata = json.loads((MODEL_DIR / "model_metadata.json").read_text())
        self.model = keras.models.load_model(MODEL_DIR / "posture_form_model.keras", compile=False)
        self.scaler = joblib.load(MODEL_DIR / "sensor_scaler.pkl")
        self.encoder = joblib.load(MODEL_DIR / "label_encoder.pkl")
        if self.model.input_shape != (None, 256, 8) or self.model.output_shape != (None, 4):
            raise ValueError("Unexpected model input or output shape.")
        if self.encoder.classes_.tolist() != self.metadata["classes"]:
            raise ValueError("Model metadata and label encoder disagree.")

    def predict(self, imu, emg):
        features = prepare_repetition(imu, emg)
        normalized = self.scaler.transform(features).astype(np.float32)
        if not np.isfinite(normalized).all():
            raise ValueError("Normalized sensor values must be finite.")
        probabilities = np.asarray(self.model(normalized[None, :, :], training=False))[0]
        if not np.isfinite(probabilities).all():
            raise RuntimeError("Model returned invalid probabilities.")
        index = int(np.argmax(probabilities))
        return {
            "predicted_class": str(self.encoder.classes_[index]),
            "probabilities": dict(zip(self.encoder.classes_.tolist(), probabilities.astype(float).tolist())),
            "confidence": float(probabilities[index]),
            "model_version": "cnn_lstm_v1",
            "features": features.tolist(),
            "training_dataset": "synthetic",
        }
