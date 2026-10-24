"""Predict one bundled repetition; run from Phase1 with python -m ML.test."""

from backend.app import recordings
from backend.inference import FormPredictor


def main():
    recording = next(iter(recordings().values()))
    result = FormPredictor().predict(recording["imu"], recording["emg"])
    print("Recording:", recording["id"])
    print("Dataset label:", recording["expected_label"])
    print("Prediction:", result["predicted_class"])
    for label, score in result["probabilities"].items():
        print(f"{label}: {score:.2%}")


if __name__ == "__main__":
    main()
