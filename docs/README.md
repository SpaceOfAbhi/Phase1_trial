# Liftly documentation

Liftly has two running parts: a Flutter application on the phone and a Python API on a computer. The API loads the already-trained model; the phone sends repetition data and displays the prediction. Nothing is trained when you use the app.

## Read in this order

| Guide | What it explains |
| --- | --- |
| **1. [Android quick start](android-quickstart.md)** | Clone the repository, start the backend, connect a phone and run the app. Includes troubleshooting and optional Wi-Fi access. |
| **2. [Architecture](architecture.md)** | The diagram, where each component lives, a complete request journey and which files to change. |
| **3. [Inference and API](inference.md)** | What the model predicts, input shape, preprocessing, parameter count and the JSON contract. |
| **4. [Hardware integration](hardware.md)** | What is missing for live sensors, the shoe/model mismatch and work that remains. |
| [Development and verification](running.md) | Browser development, local convenience scripts, test commands and verification limits. |
| [Branding](branding/README.md) | Selected logo, Manrope wordmark, source assets and icon generation. |

## What works

- Existing dashboard, exercise selection, signal charts, repetition details and workout history.
- Real model predictions from 20 bundled synthetic recordings, with the dataset label shown separately for comparison.
- Import one repetition as JSON and analyze it using the same model.
- Multiple repetitions per session, pause/resume, session completion and local history storage.
- An optional offline UI preview, explicitly labeled as mock predictions.
- A local FastAPI server with health checking, input validation and interactive API documentation.

The default flow is **recording → Flutter → Python preprocessing → saved model → four form probabilities → Flutter**. The model stays on the server. No retraining happens during use.

## Important scope

The supplied model is for bicep curls with a wrist movement sensor and biceps/triceps muscle sensors. It is not a verified shoe model. It outputs form classes, not a separate assessment of adequate muscle activation. Other exercises remain unavailable.

The supplied metadata reports approximately 89% accuracy on synthetic data. That does not establish accuracy with real people or shoe hardware. Model confidence is a class score, not a guarantee of correct or safe technique.

## Working on the code

The [architecture guide](architecture.md#repository-map) maps the main files and explains which part to change. Start frontend work in `workout_ai/lib/screens/`. Shared typography, colors and spacing live in `workout_ai/lib/theme/app_theme.dart`; cards and charts live in `workout_ai/lib/widgets/`.

The frontend can be redesigned independently of the API and model. Keep the input/output contract in [inference.md](inference.md) when changing screens.

History is stored on the phone/browser where it was created. There are no user accounts, cloud sync or backend history database.

## Layout direction

The dark UI uses consistent margins, grouped card content, larger touch targets and layouts that accommodate larger system text. It follows the hierarchy/adaptability principles in [Apple's layout guidance](https://developer.apple.com/design/human-interface-guidelines/layout) and the linked [apple-design skill](https://github.com/emilkowalski/skills/blob/main/skills/apple-design/SKILL.md), adapted to Android with platform fonts, native scrolling, docked navigation and 48px minimum icon targets. No iOS-only navigation or additional screens were introduced.
