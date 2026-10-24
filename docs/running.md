# Run and verify

[Documentation index](README.md) · [Android phone quick start](android-quickstart.md) · [Architecture](architecture.md)

For a new clone and physical phone, start with the Android guide. This page covers development commands, the original computer's scripts and verification.

Run commands from the repository root: the folder containing `backend/`, `ML/` and `workout_ai/`. Keep the backend and app running in separate terminals. The browser version is the verified target.

When cloning from GitHub, install Git LFS and run `git lfs pull` to retrieve the large EMG dataset. A small LFS pointer in place of that CSV means the dataset has not been downloaded yet.

## This computer

- Flutter 3.47.8: `D:\tools\flutter-sdk`.
- Dart package cache: `D:\tools\pub-cache`.
- Python 3.12: installed under `D:\tools\python`.
- Python environment: `Phase1\.venv`.
- Python download cache: `D:\tools\uv-cache`.

The Flutter SDK was moved off C: at the owner's request. The launch script sets the Dart cache for its process; no permanent PATH change is needed.

```powershell
# Terminal 1
.\start-backend.ps1

# Terminal 2
.\start-app.ps1
```

Open [Liftly](http://127.0.0.1:8080) and [API documentation](http://127.0.0.1:8000/docs).

If the existing preview already occupies port 8080, use that preview or stop its serving terminal before starting another server.

## First-time Python setup

With the existing `uv` installation:

```powershell
$env:UV_CACHE_DIR = 'D:\tools\uv-cache'
$env:UV_PYTHON_INSTALL_DIR = 'D:\tools\python'
uv venv --python 3.12 .venv
uv pip install --python .venv/Scripts/python.exe -r backend/requirements.txt
```

On another computer, Python 3.12 with `python -m venv .venv` and `.venv/Scripts/python.exe -m pip install -r backend/requirements.txt` is an alternative. Adjust the Flutter/cache locations in `start-app.ps1` for that machine. The exact Python package versions tested here are recorded in `backend/requirements.lock.txt`.

## Use the app

1. Leave **Offline UI preview** switched off for real model inference.
2. Choose **Begin Session → Bicep Curl → Analyze Recorded Workout**.
3. Inspect the class probabilities, source label, known dataset label and sensor charts.
4. Use **Next Rep** to analyze another bundled example. The 20 examples cycle when exhausted.
5. Pause/resume if needed. Stop the session and confirm to save it to history.
6. Open History, inspect a repetition and reload the page to confirm persistence.

**Analyze your own recording** accepts JSON in the format described in [inference.md](inference.md). Imported sessions offer **Import next rep**, so they do not silently switch to bundled examples. Invalid data is rejected with a message. This is file-data integration, not a live hardware connection.

The offline preview is useful for looking at the UI with no server. It produces mock predictions and labels them accordingly.

## Checks

```powershell
.venv/Scripts/python.exe -m pytest backend -q
.venv/Scripts/python.exe -m ML.test

Set-Location workout_ai
$env:PUB_CACHE = 'D:\tools\pub-cache'
& D:/tools/flutter-sdk/bin/flutter.bat --no-version-check test
& D:/tools/flutter-sdk/bin/flutter.bat --no-version-check analyze
& D:/tools/flutter-sdk/bin/flutter.bat --no-version-check build web
```

Backend tests exercise the real saved model, invalid input, and parity with training preprocessing. Flutter tests cover response parsing, repetition counting, error recovery, persistence and app launch.

The initial Python import can be slow while Windows scans the newly installed libraries. Subsequent backend tests completed much faster. The test client currently emits an upstream Starlette/httpx deprecation warning. Existing UI code also has analyzer style/deprecation findings; compilation and tests are checked separately.

For a static preview of the release build:

```powershell
# From Phase1, after building web
.venv/Scripts/python.exe -m http.server 8080 --bind 127.0.0.1 --directory workout_ai/build/web
```

## Mobile targets

Android and iOS platform projects have been regenerated. Their native builds have not been verified here; Android needs an installed Android SDK, and iOS needs macOS/Xcode.

For a physical Android phone, use [USB reverse forwarding](android-quickstart.md#4-connect-the-phone-over-usb) to reach the existing localhost backend. The guide also covers optional Wi-Fi access.

For an Android emulator, pass `--dart-define=API_BASE_URL=http://10.0.2.2:8000` to Flutter. Android's debug manifest permits the local HTTP development connection; release deployment should use HTTPS. The default localhost URL is suitable for the browser preview and an iOS simulator running on the backend's host. Physical phones need a reachable server address and platform network configuration; do not expose this unauthenticated prototype publicly.

## References

- [Flutter web setup and running](https://docs.flutter.dev/platform-integration/web/building)
- [Flutter HTTP requests](https://docs.flutter.dev/cookbook/networking/send-data)
- [FastAPI model startup](https://fastapi.tiangolo.com/advanced/events/)
- [Keras model loading](https://keras.io/api/models/model_saving_apis/model_saving_and_loading/)
- [Shared preferences and storage limitations](https://pub.dev/packages/shared_preferences)
