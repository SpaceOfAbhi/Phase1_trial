# Handoff

Project information belongs only in this repo; see AGENTS.md. Keep the implementation simple. The owner requested a UI-only redesign from Apple Fitness/Peloton screenshots, preserving all existing screens, text and behavior.

## State

Flutter is connected to a new local FastAPI backend and the supplied Keras model. Bundled synthetic recordings and imported repetition JSON use real inference; offline preview remains explicitly mock. Completed sessions persist locally with signal charts and source labels.

The backend owns RMS calculation, alignment, resampling and scaling. A parity test checks against training functions without running training. ML/test.py now shares the backend implementation. The model is unchanged.

Flutter SDK and new package caches are on D:, not C:. Missing web/Android/iOS platform files were regenerated. Browser target is verified; native builds are not.

## Verification

Three backend tests and three Flutter tests passed. A release web build succeeded. The shared CLI predicted GOOD for S01-1-1 with a 99.25% class score. Browser testing verified two real predictions, session saving and restoration after reload. Analyzer has existing style/deprecation findings, without compile errors. Checks are described in docs/running.md.

## Next

See docs/hardware.md before hardware work: protocol, units, calibration, timestamps and repetition boundaries are missing. The supplied model expects wrist IMU plus biceps/triceps EMG for bicep curls, which conflicts with the shoe description. Do not fabricate those channels or claim real-hardware validation.

Frontend design can change independently of inference/API. No authentication, cloud hosting, extra exercise models or automatic rep detection were added.

## UI redesign

Shared UI now uses black backgrounds, charcoal rounded surfaces, neutral system typography, lime selection accents, white pill actions, quieter charts and floating navigation. Dashboard, exercise selection, analysis, history and repetition details remain the same screens with the same content. No backend, model or session behavior was changed for the redesign. Desktop content is capped at 720px; phone layouts were visually checked at 390px. The shared primary button now uses Flutter's native filled button for keyboard/focus support.

Android layout refinement: 16px page margins, 20px main-card padding, 12px related-item gaps and 24px section spacing. Stats use two columns plus a full-width score card. Navigation is docked and respects device insets instead of overlapping content. Typography uses the platform default, icon targets are at least 48px, and large text can stack controls. Active predictions scroll above the persistent action area. Reduced motion disables decorative pulsing/bar animation.

Validation: five Flutter tests (including all screens at 360px with 1.0 and 1.6 text scales), three backend tests and the release web build passed. Refreshed docs/screenshots/dashboard.jpg. Existing analyzer/font-family and upstream test-client warnings remain; native Android/iOS builds were not run.

Publishing: the existing raw_emg.csv exceeds GitHub's ordinary-file limit. Use Git LFS; the unpublished main history is migrated with a local backup branch before the first push. Generated Flutter caches and machine-specific configuration are kept locally and excluded from version control. Branding ideas are proposals; WorkoutAI has not been renamed.

## Setup issues resolved

The original platform/cache files referred to the author's machine. Flutter had to be installed, then moved to D: on request. Its first startup tried fetching full Git tags; that unnecessary fetch was stopped. Use --no-version-check for local launch commands. The original CLI used different RMS preprocessing; it now uses the shared implementation.
