# Liftly preview data

The offline UI preview generates mock data in memory using `MockDataService`; this folder does not contain the model's recordings.

For real inference, the Python backend reads recordings from `ML/synthetic_workout_dataset/data/raw/` at the repository root. See [architecture](../../../docs/architecture.md) for the complete data flow.
