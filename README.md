# WorkoutAI

Flutter workout analysis app with a local Python API and the supplied trained CNN-LSTM model.

Start with [docs/running.md](docs/running.md). The documentation also explains [inference](docs/inference.md), [current features](docs/README.md) and [hardware requirements](docs/hardware.md).

On the configured Windows computer, run `start-backend.ps1` and `start-app.ps1` in separate terminals, then open http://127.0.0.1:8080.

The working demonstration uses synthetic bicep-curl recordings and real model inference. Shoe connectivity requires the missing hardware protocol and a model compatible with the actual sensor placement. See the hardware document before integrating devices.
