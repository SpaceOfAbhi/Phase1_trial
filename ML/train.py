
import os
import json
import joblib
import numpy as np
import pandas as pd
import matplotlib

# Use a non-interactive backend to prevent plot windows from blocking execution.
matplotlib.use("Agg")

import matplotlib.pyplot as plt
import seaborn as sns
import tensorflow as tf

from scipy.interpolate import interp1d
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.metrics import (
    classification_report,
    confusion_matrix,
)

from tensorflow.keras import Sequential
from tensorflow.keras.layers import (
    Input,
    Conv1D,
    MaxPooling1D,
    LSTM,
    Dense,
    Dropout,
    BatchNormalization,
)
from tensorflow.keras.callbacks import EarlyStopping, ModelCheckpoint


# ============================================================
# 1. CONFIGURATION
# ============================================================

DATA_DIR = "synthetic_workout_dataset/data"
OUTPUT_DIR = "model_outputs"

SEQUENCE_LENGTH = 256
BATCH_SIZE = 32
EPOCHS = 50
RANDOM_STATE = 42

KEYS = ["subject_id", "session_id", "rep_id"]

IMU_FEATURES = [
    "accelerometer_x",
    "accelerometer_y",
    "accelerometer_z",
    "gyroscope_x",
    "gyroscope_y",
    "gyroscope_z",
]

ALL_FEATURES = IMU_FEATURES + [
    "biceps_rms",
    "triceps_rms",
]

os.makedirs(OUTPUT_DIR, exist_ok=True)

np.random.seed(RANDOM_STATE)
tf.random.set_seed(RANDOM_STATE)


# ============================================================
# 2. LOAD DATASETS
# ============================================================

print("\n========== LOADING DATASETS ==========")

imu = pd.read_csv(f"{DATA_DIR}/raw/raw_imu.csv")
emg = pd.read_csv(f"{DATA_DIR}/raw/raw_emg.csv")
labels = pd.read_csv(f"{DATA_DIR}/raw/labels.csv")

print("Datasets loaded.")
print("IMU rows:", len(imu))
print("EMG rows:", len(emg))
print("Labels:", len(labels))


# ============================================================
# 3. VERIFY REPETITION IDS
# ============================================================

print("\n========== VERIFYING DATA ==========")

imu_reps = set(imu.groupby(KEYS).groups)
emg_reps = set(emg.groupby(KEYS).groups)
label_reps = set(labels.groupby(KEYS).groups)

print("IMU and EMG match:", imu_reps == emg_reps)
print("IMU and labels match:", imu_reps == label_reps)

if not (imu_reps == emg_reps == label_reps):
    raise ValueError(
        "IMU, EMG, and label repetition IDs do not match."
    )

if labels.duplicated(KEYS).any():
    raise ValueError("Duplicate repetition labels detected.")

print(
    "IMU median sampling interval:",
    imu.sort_values(KEYS + ["timestamp"])
       .groupby(KEYS)["timestamp"]
       .diff()
       .median()
)

print(
    "EMG median sampling interval:",
    emg.sort_values(KEYS + ["timestamp"])
       .groupby(KEYS)["timestamp"]
       .diff()
       .median()
)


# ============================================================
# 4. CALCULATE EMG RMS ENVELOPE
# ============================================================

def calculate_rms(signal, window_size=50):
    """
    Calculate a moving RMS envelope.

    EMG sampling rate: approximately 1000 Hz.
    Window size: 50 samples, approximately 50 ms.
    """

    signal = np.asarray(signal, dtype=np.float64)

    if len(signal) == 0:
        return np.array([], dtype=np.float64)

    squared = signal ** 2
    window = np.ones(window_size) / window_size

    rms = np.sqrt(
        np.convolve(squared, window, mode="same")
    )

    return rms


# ============================================================
# 5. SYNCHRONIZE IMU AND EMG FOR ONE REPETITION
# ============================================================

def synchronize_repetition(imu_rep, emg_rep):

    imu_rep = imu_rep.sort_values("timestamp")
    emg_rep = emg_rep.sort_values("timestamp")

    imu_time = imu_rep["timestamp"].to_numpy(dtype=float)
    emg_time = emg_rep["timestamp"].to_numpy(dtype=float)

    if len(imu_time) < 2 or len(emg_time) < 2:
        return None

    # Calculate EMG activation envelopes.
    biceps_rms = calculate_rms(
        emg_rep["biceps_emg"].to_numpy()
    )

    triceps_rms = calculate_rms(
        emg_rep["triceps_emg"].to_numpy()
    )

    # Find the overlapping time interval.
    start_time = max(imu_time[0], emg_time[0])
    end_time = min(imu_time[-1], emg_time[-1])

    valid = (
        (imu_time >= start_time)
        & (imu_time <= end_time)
    )

    imu_values = imu_rep[IMU_FEATURES].to_numpy(
        dtype=np.float64
    )

    imu_time = imu_time[valid]
    imu_values = imu_values[valid]

    if len(imu_time) < 2:
        return None

    # Interpolate EMG envelopes to the IMU timestamps.
    biceps_aligned = np.interp(
        imu_time,
        emg_time,
        biceps_rms,
    )

    triceps_aligned = np.interp(
        imu_time,
        emg_time,
        triceps_rms,
    )

    # Six IMU features + two EMG features.
    features = np.column_stack([
        imu_values,
        biceps_aligned,
        triceps_aligned,
    ])

    return imu_time, features


# ============================================================
# 6. RESAMPLE EACH REPETITION TO A FIXED LENGTH
# ============================================================

def create_fixed_sequence(
    features,
    sequence_length=SEQUENCE_LENGTH,
):
    original_positions = np.linspace(
        0,
        1,
        len(features),
    )

    target_positions = np.linspace(
        0,
        1,
        sequence_length,
    )

    interpolator = interp1d(
        original_positions,
        features,
        axis=0,
        kind="linear",
    )

    return interpolator(
        target_positions
    ).astype(np.float32)


# ============================================================
# 7. GROUP DATA AND PROCESS REPETITIONS
# ============================================================

print("\n========== PREPROCESSING ==========")
print("Grouping EMG data...")

emg_groups = {
    key: group
    for key, group in emg.groupby(
        KEYS,
        sort=False,
    )
}

label_lookup = labels.set_index(KEYS)["form_label"]

print("EMG grouping complete.")
print("Processing repetitions...")

X_list = []
y_list = []
subject_list = []

imu_groups = imu.groupby(KEYS, sort=False)

total_repetitions = len(imu_groups)

for i, (rep_key, imu_rep) in enumerate(
    imu_groups,
    start=1,
):

    emg_rep = emg_groups.get(rep_key)

    if emg_rep is None or rep_key not in label_lookup.index:
        continue

    result = synchronize_repetition(
        imu_rep,
        emg_rep,
    )

    if result is None:
        continue

    _, features = result

    sequence = create_fixed_sequence(
        features,
        SEQUENCE_LENGTH,
    )

    X_list.append(sequence)
    y_list.append(label_lookup.loc[rep_key])
    subject_list.append(rep_key[0])

    if i % 200 == 0 or i == total_repetitions:
        print(
            f"Processed {i}/{total_repetitions} repetitions"
        )

del emg_groups
del emg
del imu
del imu_groups


# ============================================================
# 8. CONVERT TO NUMPY ARRAYS
# ============================================================

X = np.asarray(X_list, dtype=np.float32)
y = np.asarray(y_list)
subjects = np.asarray(subject_list)

print("\n========== PREPROCESSING RESULTS ==========")
print("X shape:", X.shape)
print("y shape:", y.shape)
print("Unique subjects:", len(np.unique(subjects)))
print("All values finite:", np.isfinite(X).all())

print("\nClass distribution:")
print(pd.Series(y).value_counts())

print("\nFeature names:")
print(ALL_FEATURES)

if len(X) == 0:
    raise ValueError("No valid repetitions were processed.")

if not np.isfinite(X).all():
    raise ValueError("Input data contains NaN or infinite values.")


# ============================================================
# 9. SPLIT DATA BY SUBJECT
# ============================================================

print("\n========== DATASET SPLIT ==========")

unique_subjects = np.unique(subjects)

train_subjects, remaining_subjects = train_test_split(
    unique_subjects,
    test_size=0.30,
    random_state=RANDOM_STATE,
)

val_subjects, test_subjects = train_test_split(
    remaining_subjects,
    test_size=0.50,
    random_state=RANDOM_STATE,
)

train_mask = np.isin(subjects, train_subjects)
val_mask = np.isin(subjects, val_subjects)
test_mask = np.isin(subjects, test_subjects)

X_train, y_train = X[train_mask], y[train_mask]
X_val, y_val = X[val_mask], y[val_mask]
X_test, y_test = X[test_mask], y[test_mask]

print("Training subjects:", len(train_subjects))
print("Validation subjects:", len(val_subjects))
print("Testing subjects:", len(test_subjects))

print("Training:", X_train.shape, y_train.shape)
print("Validation:", X_val.shape, y_val.shape)
print("Testing:", X_test.shape, y_test.shape)

print("\nSubject overlap:")
print(
    "Train/Validation:",
    len(set(train_subjects) & set(val_subjects)),
)
print(
    "Train/Test:",
    len(set(train_subjects) & set(test_subjects)),
)
print(
    "Validation/Test:",
    len(set(val_subjects) & set(test_subjects)),
)


# ============================================================
# 10. NORMALIZE FEATURES
# ============================================================

print("\n========== NORMALIZATION ==========")

n_features = X_train.shape[2]

X_train_2d = X_train.reshape(-1, n_features)
X_val_2d = X_val.reshape(-1, n_features)
X_test_2d = X_test.reshape(-1, n_features)

scaler = StandardScaler()

# Fit only on the training set to prevent data leakage.
scaler.fit(X_train_2d)

X_train = scaler.transform(
    X_train_2d
).reshape(X_train.shape).astype(np.float32)

X_val = scaler.transform(
    X_val_2d
).reshape(X_val.shape).astype(np.float32)

X_test = scaler.transform(
    X_test_2d
).reshape(X_test.shape).astype(np.float32)

print("Training feature means:")
print(np.round(X_train.mean(axis=(0, 1)), 3))

print("Training feature standard deviations:")
print(np.round(X_train.std(axis=(0, 1)), 3))

print(
    "All normalized values finite:",
    np.isfinite(X_train).all()
    and np.isfinite(X_val).all()
    and np.isfinite(X_test).all(),
)


# ============================================================
# 11. ENCODE CLASS LABELS
# ============================================================

print("\n========== LABEL ENCODING ==========")

label_encoder = LabelEncoder()

y_train_encoded = label_encoder.fit_transform(y_train)
y_val_encoded = label_encoder.transform(y_val)
y_test_encoded = label_encoder.transform(y_test)

for index, label in enumerate(label_encoder.classes_):
    print(f"{label} -> {index}")

num_classes = len(label_encoder.classes_)

print("Number of classes:", num_classes)


# ============================================================
# 12. BUILD CNN-LSTM MODEL
# ============================================================

print("\n========== BUILDING MODEL ==========")

model = Sequential([
    Input(shape=(SEQUENCE_LENGTH, n_features)),

    Conv1D(
        filters=64,
        kernel_size=5,
        activation="relu",
    ),
    BatchNormalization(),
    MaxPooling1D(pool_size=2),

    Conv1D(
        filters=128,
        kernel_size=3,
        activation="relu",
    ),
    BatchNormalization(),
    MaxPooling1D(pool_size=2),

    LSTM(64),

    Dense(64, activation="relu"),
    Dropout(0.3),

    Dense(num_classes, activation="softmax"),
])

model.compile(
    optimizer="adam",
    loss="sparse_categorical_crossentropy",
    metrics=["accuracy"],
)

model.summary()


# ============================================================
# 13. TRAIN MODEL
# ============================================================

print("\n========== TRAINING MODEL ==========")

best_model_path = os.path.join(
    OUTPUT_DIR,
    "best_cnn_lstm.keras",
)

early_stopping = EarlyStopping(
    monitor="val_loss",
    patience=8,
    restore_best_weights=True,
    verbose=1,
)

checkpoint = ModelCheckpoint(
    best_model_path,
    monitor="val_loss",
    save_best_only=True,
    verbose=1,
)

history = model.fit(
    X_train,
    y_train_encoded,
    validation_data=(
        X_val,
        y_val_encoded,
    ),
    epochs=EPOCHS,
    batch_size=BATCH_SIZE,
    callbacks=[
        early_stopping,
        checkpoint,
    ],
    verbose=1,
)


# ============================================================
# 14. EVALUATE ON THE TEST SET
# ============================================================

print("\n========== TEST RESULTS ==========")

test_loss, test_accuracy = model.evaluate(
    X_test,
    y_test_encoded,
    verbose=0,
)

print(f"Test Loss: {test_loss:.4f}")
print(f"Test Accuracy: {test_accuracy:.4f}")
print(f"Test Accuracy: {test_accuracy * 100:.2f}%")

print("\nGenerating predictions...")

predicted_probabilities = model.predict(
    X_test,
    verbose=0,
)

y_pred = np.argmax(
    predicted_probabilities,
    axis=1,
)

print("\n========== CLASSIFICATION REPORT ==========")

print(
    classification_report(
        y_test_encoded,
        y_pred,
        labels=np.arange(num_classes),
        target_names=label_encoder.classes_,
        zero_division=0,
    )
)


# ============================================================
# 15. SAVE CONFUSION MATRIX WITHOUT BLOCKING EXECUTION
# ============================================================

print("\nSaving confusion matrix...")

cm = confusion_matrix(
    y_test_encoded,
    y_pred,
    labels=np.arange(num_classes),
)

plt.figure(figsize=(10, 7))

sns.heatmap(
    cm,
    annot=True,
    fmt="d",
    cmap="Blues",
    xticklabels=label_encoder.classes_,
    yticklabels=label_encoder.classes_,
)

plt.xlabel("Predicted Label")
plt.ylabel("Actual Label")
plt.title("CNN-LSTM Test Confusion Matrix")
plt.xticks(rotation=30, ha="right")
plt.yticks(rotation=0)
plt.tight_layout()

confusion_matrix_path = os.path.join(
    OUTPUT_DIR,
    "confusion_matrix.png",
)

plt.savefig(
    confusion_matrix_path,
    dpi=300,
    bbox_inches="tight",
)

plt.close()

print("Confusion matrix saved:", confusion_matrix_path)


# ============================================================
# 16. SAVE TRAINED MODEL
# ============================================================

print("\n========== SAVING MODEL ==========")

final_model_path = os.path.join(
    OUTPUT_DIR,
    "posture_form_model.keras",
)

print("Saving CNN-LSTM model...")

model.save(final_model_path)

print("Model saved:", final_model_path)


# ============================================================
# 17. SAVE PREPROCESSING OBJECTS
# ============================================================

scaler_path = os.path.join(
    OUTPUT_DIR,
    "sensor_scaler.pkl",
)

encoder_path = os.path.join(
    OUTPUT_DIR,
    "label_encoder.pkl",
)

print("Saving feature scaler...")

joblib.dump(scaler, scaler_path)

print("Scaler saved:", scaler_path)

print("Saving label encoder...")

joblib.dump(label_encoder, encoder_path)

print("Label encoder saved:", encoder_path)


# ============================================================
# 18. SAVE MODEL METADATA
# ============================================================

metadata = {
    "sequence_length": SEQUENCE_LENGTH,
    "num_features": n_features,
    "features": ALL_FEATURES,
    "classes": label_encoder.classes_.tolist(),
    "sampling_rate_hz": 100,
    "test_accuracy": float(test_accuracy),
    "test_loss": float(test_loss),
    "dataset_type": "synthetic",
}

metadata_path = os.path.join(
    OUTPUT_DIR,
    "model_metadata.json",
)

print("Saving model metadata...")

with open(metadata_path, "w", encoding="utf-8") as file:
    json.dump(
        metadata,
        file,
        indent=4,
    )

print("Metadata saved:", metadata_path)


# ============================================================
# 19. COMPLETION SUMMARY
# ============================================================

print("\n========== PIPELINE COMPLETED ==========")

print("Test accuracy:", f"{test_accuracy * 100:.2f}%")

print("\nGenerated files:")

for filename in [
    "best_cnn_lstm.keras",
    "posture_form_model.keras",
    "sensor_scaler.pkl",
    "label_encoder.pkl",
    "model_metadata.json",
    "confusion_matrix.png",
]:
    filepath = os.path.join(
        OUTPUT_DIR,
        filename,
    )

    if os.path.exists(filepath):
        size_mb = os.path.getsize(filepath) / (1024 * 1024)

        print(
            f"  {filename}: "
            f"{size_mb:.2f} MB"
        )
    else:
        print(f"  {filename}: NOT FOUND")

print("\nAll processing and saving operations finished.")

