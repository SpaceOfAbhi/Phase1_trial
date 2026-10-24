# Clone and run Liftly on an Android phone

[Documentation index](README.md) · [Architecture](architecture.md)

The **Flutter app runs on your phone**. The **Python backend and trained model run on your computer**. The app sends a complete repetition to the backend and receives a prediction. Keep the backend running while testing real inference.

Start with USB, which avoids Wi-Fi addresses and firewall changes. This guide assumes you already develop Flutter apps. The backend, Flutter tests and browser build have been checked; native Android installation has not yet been verified on a physical device.

## 1. Prerequisites

- Flutter and Android SDK/platform-tools, with `flutter`, `adb` and Git available in your terminal. `flutter doctor` should show a working Android toolchain.
- Flutter **3.47.8** is the tested version. The committed dependency lock requires Flutter >=3.44.0 and Dart >=3.13.0; use the tested version to minimize differences.
- **Python 3.12, 64-bit**, for the backend. No model training or GPU setup is needed for this demonstration.
- [Git LFS](https://docs.github.com/en/repositories/working-with-files/managing-large-files/installing-git-large-file-storage). The raw EMG dataset uses LFS and is approximately 198 MB.
- An Android phone and USB data cable.

Use your own SDK locations. `start-app.ps1` contains the original computer's D: paths; the commands below do not depend on that script.

## 2. Clone the repository

```shell
git lfs install
git clone https://github.com/SpaceOfAbhi/Phase1_trial.git liftly
cd liftly
git lfs pull
```

This is the **repository root**, containing `backend/`, `ML/` and `workout_ai/`. The Flutter project is the `workout_ai/` subfolder. If GitHub requests authentication, use an account with access to the repository.

Check that `ML/synthetic_workout_dataset/data/raw/raw_emg.csv` contains CSV rows rather than a short text starting with `version https://git-lfs.github.com/spec/v1`. A short pointer means the LFS download is missing.

## 3. Install and start the backend

Open a terminal in the repository root.

**Windows / PowerShell:**

```powershell
py -3.12 -m venv .venv
.\.venv\Scripts\python.exe -m pip install --upgrade pip
.\.venv\Scripts\python.exe -m pip install -r backend/requirements.txt
.\.venv\Scripts\python.exe -m uvicorn backend.app:app --host 127.0.0.1 --port 8000
```

**macOS / Linux equivalent:**

```shell
python3.12 -m venv .venv
.venv/bin/python -m pip install --upgrade pip
.venv/bin/python -m pip install -r backend/requirements.txt
.venv/bin/python -m uvicorn backend.app:app --host 127.0.0.1 --port 8000
```

The Python package set was verified on Windows with Python 3.12; installation on other operating systems is not yet verified. Dependency installation can take time because TensorFlow is included.

Wait for `Application startup complete`. Startup loads the model, scaler and label encoder and reads the bundled examples. Open [health](http://127.0.0.1:8000/health) on the computer and confirm `"model_loaded": true`. [API docs](http://127.0.0.1:8000/docs) show the routes. Leave this terminal open.

Do not run `ML/train.py` to start the app: it trains a model. The saved model is already in `ML/model_outputs/`.

## 4. Connect the phone over USB

Enable **Developer options → USB debugging**, connect the cable and accept the phone's debugging authorization prompt. In a second terminal, run:

```shell
adb devices
flutter devices
adb reverse tcp:8000 tcp:8000
```

The phone should appear as an authorized Android device. `adb reverse` connects **port 8000 on the phone to port 8000 on the computer**. The app's localhost address can then reach the computer's API over USB.

Open `http://127.0.0.1:8000/health` in the phone's browser. It should return the same health response as on the computer. Re-run the reverse command if the mapping is lost after reconnecting or restarting the phone.

If multiple Android devices are connected, use `adb -s DEVICE_ID reverse tcp:8000 tcp:8000`, replacing `DEVICE_ID` with the desired phone's ID.

## 5. Run Flutter on the phone

In the second terminal, starting from the repository root:

```shell
cd workout_ai
flutter pub get
flutter run --debug --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

Select the Android phone if Flutter asks for a target. To select it explicitly, add `-d DEVICE_ID`, using the ID from `flutter devices`.

This installs and starts Liftly directly; you do not need to manually copy an APK. Use debug mode for local HTTP: the Android debug manifest permits cleartext development traffic. A release deployment should use an HTTPS backend.

## 6. Confirm the complete flow

1. Leave **Offline UI preview** off so the app uses the real saved model.
2. Choose **Begin Session → Bicep Curl → Analyze Recorded Workout**.
3. A prediction, probabilities and sensor charts should appear. **Next Rep** analyzes the next bundled recording.
4. Stop and confirm the session. Open **History**, then tap a repetition to inspect it.

The bundled recordings are synthetic, but predictions in this mode come from the real trained model. Live shoe or Bluetooth data is not connected. [Inference](inference.md) explains importing a compatible recording.

To inspect screens without Python, switch **Offline UI preview** on. It generates mock predictions; it does not run the model.

## Optional: Wi-Fi instead of the USB API connection

Use this after USB works. Installing the app on a phone does not move the Python model onto the phone.

1. Put the phone and computer on the same trusted local network.
2. Stop the backend and restart it with `--host 0.0.0.0` instead of `--host 127.0.0.1`.
3. Find the computer's local IPv4 address (`ipconfig` on Windows). Allow incoming TCP port 8000 on that private network if the firewall asks.
4. Confirm the phone can open `http://COMPUTER_IP:8000/health`, replacing `COMPUTER_IP` with the actual address.
5. Run the native app with that address, for example:

```shell
flutter run --debug --dart-define=API_BASE_URL=http://192.168.1.25:8000
```

Replace the example IP with yours. Stop and rerun Flutter when changing `API_BASE_URL`; hot reload does not change this build-time setting. `0.0.0.0` is a server bind address, not an address to put in the app. The prototype API has no authentication; do not forward its port to the public internet.

## Troubleshooting

| Symptom | Check |
| --- | --- |
| Device absent or `unauthorized` | Unlock the phone, accept USB debugging, check cable/driver and retry `adb devices`. |
| `adb` not recognized | Add the Android SDK's `platform-tools` directory to PATH or run `adb` by its full path. |
| Flutter dependency resolution fails | Check Flutter/Dart versions in step 1; run `flutter doctor` for toolchain issues. |
| Python cannot find compatible packages | Confirm 64-bit Python 3.12. Versions are pinned in `backend/requirements.lock.txt`. |
| Backend fails while reading CSV data | Run `git lfs pull` and check that the EMG file is CSV, not a pointer. |
| Port 8000 already occupied | Reuse the running Liftly backend or stop its terminal before starting another copy. |
| App cannot reach the analysis server | Check `/health`, keep Python running, repeat `adb reverse` and verify Flutter's API URL. |
| Preview works but real analysis fails | Preview is independent of Python; check the backend and phone connection separately. |
| Wi-Fi address unreachable | Check IP, bind address, private-network firewall and whether Wi-Fi isolates devices. |

## References

- [Flutter: connect an Android device](https://docs.flutter.dev/platform-integration/android/setup)
- [Android: reverse port forwarding](https://developer.android.com/develop/ui/views/layout/webapps/access-local-server)
- [Python: virtual environments](https://docs.python.org/3.12/library/venv.html)
- [FastAPI: run a server](https://fastapi.tiangolo.com/deployment/manually/)
