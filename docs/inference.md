# Inference for this model

Inference means using an already trained model to calculate an output from new input. Training adjusts the model's internal parameters; inference keeps them fixed.

Here, **one example is one complete repetition**, containing many sensor readings over time. It is not one prediction per raw sensor sample.

## From sensors to prediction

1. Collect one repetition's timestamped movement and muscle readings.
2. Calculate muscle-signal strength using a centered 50-sample root-mean-square (RMS) window, matching `ML/train.py`.
3. Keep the time interval shared by both streams and interpolate the two muscle envelopes onto the movement timestamps.
4. Resample the whole repetition to 256 time steps.
5. Put the eight channels in the training order and normalize with the saved scaler. Never fit a new scaler during inference.
6. Add an outer dimension for one example: `(1, 256, 8)`.
7. Run the saved model and choose the class with the highest probability.

The 256 steps stretch across the whole repetition; they do not mean 256 repetitions or a fixed 2.56-second duration.

| Column | Reading |
| --- | --- |
| 0–2 | Acceleration on x, y and z |
| 3–5 | Rotation rate on x, y and z |
| 6 | Biceps RMS |
| 7 | Triceps RMS |

The convolution layers find patterns in nearby readings; the LSTM processes their sequence over the repetition. The final layer returns probabilities for `EXCESSIVE_ELBOW_MOVEMENT`, `EXCESSIVE_SWING`, `GOOD`, and `PARTIAL_ROM` in that order.

Example output, for illustration only: `[0.02, 0.03, 0.92, 0.03]` predicts `GOOD` with a score of 0.92. It does not prove a 92% chance that a person's technique is safe.

## Parameters

Verified from the saved architecture: **81,540 trainable parameters**, plus **384 non-trainable normalization statistics**, for **81,924 total model parameters/statistics**. Optimizer bookkeeping is excluded.

| Layer | Parameter count |
| --- | ---: |
| First convolution | 2,624 |
| First normalization | 256 |
| Second convolution | 24,704 |
| Second normalization | 512 |
| LSTM | 49,408 |
| Hidden dense layer | 4,160 |
| Output dense layer | 260 |

The input's 2,048 readings (`256 × 8`) are different from the learned parameters. The input changes with each repetition; the trained parameters stay in the saved model.

## API contract

`POST /predict`, with `Content-Type: application/json`:

```json
{
  "exercise": "bicep_curl",
  "imu": [[0.0, 1, 2, 3, 4, 5, 6], [0.01, 1, 2, 3, 4, 5, 6]],
  "emg": [[0.0, 0.1, 0.2], [0.001, 0.12, 0.18]]
}
```

This illustrates row layout; it is intentionally too short for a valid muscle recording. A valid request needs at least 50 EMG rows, at least two IMU rows in the overlapping time interval, and strictly increasing timestamps in each stream.

- IMU row: `[timestamp_seconds, ax, ay, az, gx, gy, gz]`.
- EMG row: `[timestamp_seconds, biceps_emg, triceps_emg]`.
- Timestamps share a clock. Movement data was generated at 100 Hz and muscle data at approximately 1,000 Hz.
- Send raw readings, not already normalized values or precomputed RMS envelopes.
- All values must be finite. Limits are 5,000 IMU rows and 50,000 EMG rows per request.
- Hardware units, axes and calibration must match training; the supplied sensor metadata does not define all physical units. Confirm these before using real hardware.

The response contains `predicted_class`, a `probabilities` map, `confidence`, `model_version`, `training_dataset`, and the unnormalized `256 × 8` prepared `features` used to draw charts. Dataset labels are never supplied to the model.

Other routes:

- `GET /health`: confirms successful model startup and returns metadata.
- `GET /recordings`: lists 20 bundled examples, source and known labels.
- `GET /recordings/{id}`: returns one recording's raw streams.
- `GET /docs`: interactive API documentation.

## Where inference happens

`backend/inference.py`, in `FormPredictor.predict`. The model, scaler and encoder are loaded once when the API starts. `ML/test.py` uses the same implementation for a command-line demonstration. The original separate prediction preprocessing has been replaced so API and CLI do not drift apart.

`backend/test_api.py` compares preprocessing directly against the pure functions extracted from the original training script, without importing that script or starting training.
