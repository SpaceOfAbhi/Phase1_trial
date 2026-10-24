# Liftly

Liftly is a university workout-form prototype: a Flutter app sends one recorded repetition to a Python API, which runs the supplied trained model and returns a form prediction.

**Start here: [clone and run on an Android phone](docs/android-quickstart.md).** The app runs on the phone; the API and model run on your computer. USB is the simplest development connection.

Read the [documentation index](docs/README.md) for the whole project, or open the [architecture diagram](docs/architecture.md) to see how its parts connect.

The working demonstration uses synthetic bicep-curl recordings and real model inference. Shoe connectivity requires the missing hardware protocol and a model compatible with the actual sensor placement. See the hardware document before integrating devices.
