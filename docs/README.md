# WorkoutAI

A university prototype: Flutter displays workout recordings; a local Python API runs the supplied trained model and returns form predictions. Keep all project information in this repository, outside the owner's second-brain vaults.

- [Run the app](running.md)
- [Understand inference and the input format](inference.md)
- [Hardware requirements and remaining work](hardware.md)

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

## Main files

| File | Responsibility |
| --- | --- |
| `backend/app.py` | API, validation, bundled recording access and startup |
| `backend/inference.py` | Training-compatible preprocessing and saved-model prediction |
| `backend/test_api.py` | Real inference, validation and preprocessing parity checks |
| `ML/train.py` | Original training pipeline; running it starts training |
| `ML/test.py` | Command-line demonstration using the shared inference implementation |
| `ML/model_outputs/` | Model, feature scaler, label encoder and metadata used by the API |
| `workout_ai/lib/services/api_service.dart` | Flutter HTTP connection |
| `workout_ai/lib/services/analysis_provider.dart` | Sessions, inference requests and local history |
| `workout_ai/lib/models/workout_models.dart` | App data and history serialization |

The frontend can be redesigned independently of the API and model. Keep the input/output contract in [inference.md](inference.md) when changing screens.

## Layout direction

The dark UI uses consistent margins, grouped card content, larger touch targets and layouts that accommodate larger system text. It follows the hierarchy/adaptability principles in [Apple's layout guidance](https://developer.apple.com/design/human-interface-guidelines/layout) and the linked [apple-design skill](https://github.com/emilkowalski/skills/blob/main/skills/apple-design/SKILL.md), adapted to Android with platform fonts, native scrolling, docked navigation and 48px minimum icon targets. No iOS-only navigation or additional screens were introduced.
