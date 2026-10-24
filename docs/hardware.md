# Hardware integration

The supplied sensor configuration places an IMU near the wrist and muscle-signal electrodes on the biceps and triceps. The trained exercise is the bicep curl. A shoe-only device is not compatible with these assumptions merely because it also supplies movement data.

## Needed from the device owner

1. Actual sensor types and mounting locations.
2. Connection method: Bluetooth, Wi-Fi, USB, or another transport; service identifiers and packet examples where applicable.
3. Channel order, units, sensor axes and calibration procedure.
4. Sampling rates and how timestamps are synchronized between sensors.
5. How repetition start/end boundaries are indicated, or recorded continuous streams from which to develop and test a detector.

Once these are available, implement a Flutter device reader that assembles one repetition into the input format in [inference.md](inference.md). The existing API can process compatible readings without changing the model interface.

## What this version does not claim

- No Bluetooth connection or shoe firmware is implemented; the protocol is absent from the repository.
- No automatic detection of repetition boundaries in continuous data. The app counts the completed repetitions it analyzes.
- No verified performance on real sensor hardware; calibration and real-data validation are required.
- No independent muscle-activation adequacy score. RMS charts show signal strength, not a calibrated medical or training assessment.
- No model for squats, deadlifts or shoulder presses. Their existing placeholder cards remain disabled.

If the project must use shoe-only measurements, first agree on the exercise and outputs the sensors can support, then collect appropriately placed and labeled data and train/validate a matching model. Do not invent missing biceps/triceps channels.

## Storage and deployment limits

Workout history is stored on the current device/browser using the existing shared-preferences package. It includes chart data and source labels. It is suitable for this prototype, has no account synchronization, and can be lost when browser data is cleared. A failed save leaves the current session open for retry. Browser storage quotas may limit long histories; use a database/export if this becomes a real collection tool.

The API is bound to localhost and has no authentication. Browser origins are restricted to localhost/127.0.0.1. Keep it local for the university demonstration; public hosting needs authentication, HTTPS, request-size/rate limits and a data-retention decision.
