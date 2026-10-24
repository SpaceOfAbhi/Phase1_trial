import os
import json
import joblib
import numpy as np
import pandas as pd
import tensorflow as tf

# --------------------------------------------------
# 1. File paths
# --------------------------------------------------

DATA_DIR = "synthetic_workout_dataset/data/raw"
OUTPUT_DIR = "model_outputs"

IMU_FILE = os.path.join(DATA_DIR, "raw_imu.csv")
EMG_FILE = os.path.join(DATA_DIR, "raw_emg.csv")
LABEL_FILE = os.path.join(DATA_DIR, "labels.csv")

# --------------------------------------------------
# 2. Load saved model and preprocessing objects
# --------------------------------------------------

print("Loading saved model...")

model = tf.keras.models.load_model(
    os.path.join(OUTPUT_DIR, "posture_form_model.keras")
)

scaler = joblib.load(
    os.path.join(OUTPUT_DIR, "sensor_scaler.pkl")
)

label_encoder = joblib.load(
    os.path.join(OUTPUT_DIR, "label_encoder.pkl")
)

with open(
    os.path.join(OUTPUT_DIR, "model_metadata.json"),
    "r",
    encoding="utf-8"
) as file:
    metadata = json.load(file)

SEQUENCE_LENGTH = metadata["sequence_length"]

print("Model loaded successfully!")

# --------------------------------------------------
# 3. Load the dataset
# --------------------------------------------------

print("\nLoading sensor data...")

imu = pd.read_csv(IMU_FILE)
emg = pd.read_csv(EMG_FILE)
labels = pd.read_csv(LABEL_FILE)

print("IMU rows:", len(imu))
print("EMG rows:", len(emg))
print("Label rows:", len(labels))

# --------------------------------------------------
# 4. Select one repetition
# --------------------------------------------------

keys = ["subject_id", "session_id", "rep_id"]

# Select the first repetition present in the labels
sample_label = labels.iloc[0]

subject = sample_label["subject_id"]
session = sample_label["session_id"]
rep = sample_label["rep_id"]

print("\nSelected repetition:")
print("Subject:", subject)
print("Session:", session)
print("Repetition:", rep)
print("Actual label:", sample_label["form_label"])

imu_rep = imu[
    (imu["subject_id"] == subject)
    & (imu["session_id"] == session)
    & (imu["rep_id"] == rep)
].copy()

emg_rep = emg[
    (emg["subject_id"] == subject)
    & (emg["session_id"] == session)
    & (emg["rep_id"] == rep)
].copy()

imu_rep = imu_rep.sort_values("timestamp")
emg_rep = emg_rep.sort_values("timestamp")

if len(imu_rep) == 0 or len(emg_rep) == 0:
    raise ValueError(
        "No matching IMU or EMG samples found for this repetition."
    )

# --------------------------------------------------
# 5. Calculate EMG RMS envelopes
# --------------------------------------------------

window_size = 50

for column in ["biceps_emg", "triceps_emg"]:
    squared = emg_rep[column] ** 2

    emg_rep[column + "_rms"] = np.sqrt(
        squared.rolling(
            window=window_size,
            min_periods=window_size
        ).mean()
    )

emg_rep = emg_rep.dropna(
    subset=["biceps_emg_rms", "triceps_emg_rms"]
)

if len(emg_rep) == 0:
    raise ValueError("Not enough EMG samples to calculate RMS.")

# --------------------------------------------------
# 6. Align EMG features with IMU timestamps
# --------------------------------------------------

imu_times = imu_rep["timestamp"].to_numpy()
emg_times = emg_rep["timestamp"].to_numpy()

biceps_rms = np.interp(
    imu_times,
    emg_times,
    emg_rep["biceps_emg_rms"].to_numpy()
)

triceps_rms = np.interp(
    imu_times,
    emg_times,
    emg_rep["triceps_emg_rms"].to_numpy()
)

# The eight features must follow training order.
feature_columns = [
    "accelerometer_x",
    "accelerometer_y",
    "accelerometer_z",
    "gyroscope_x",
    "gyroscope_y",
    "gyroscope_z"
]

sensor_data = imu_rep[feature_columns].to_numpy()

sensor_data = np.column_stack([
    sensor_data,
    biceps_rms,
    triceps_rms
])

# --------------------------------------------------
# 7. Resample to 256 time steps
# --------------------------------------------------

old_positions = np.linspace(
    0, len(sensor_data) - 1, len(sensor_data)
)

new_positions = np.linspace(
    0, len(sensor_data) - 1, SEQUENCE_LENGTH
)

sequence = np.column_stack([
    np.interp(
        new_positions,
        old_positions,
        sensor_data[:, feature]
    )
    for feature in range(sensor_data.shape[1])
])

# --------------------------------------------------
# 8. Normalize using the saved scaler
# --------------------------------------------------

sequence = scaler.transform(sequence)

X_sample = sequence[np.newaxis, :, :].astype(np.float32)

print("\nInput shape:", X_sample.shape)

# --------------------------------------------------
# 9. Predict workout form
# --------------------------------------------------

probabilities = model.predict(X_sample, verbose=0)[0]

predicted_index = np.argmax(probabilities)

predicted_label = label_encoder.inverse_transform(
    [predicted_index]
)[0]

print("\n========== PREDICTION ==========")
print("Actual label:   ", sample_label["form_label"])
print("Predicted label:", predicted_label)
print(
    "Confidence:     ",
    f"{probabilities[predicted_index] * 100:.2f}%"
)

print("\nClass probabilities:")

for name, probability in zip(
    label_encoder.classes_,
    probabilities
):
    print(f"{name}: {probability * 100:.2f}%")

print("\nTest completed!")