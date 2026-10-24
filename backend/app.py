from contextlib import asynccontextmanager
from functools import lru_cache
from pathlib import Path
from threading import Lock
from typing import Annotated, Literal

import pandas as pd
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, ConfigDict, Field, FiniteFloat

from .inference import FormPredictor

DATA_DIR = Path(__file__).resolve().parents[1] / "ML/synthetic_workout_dataset/data/raw"
KEYS = ["subject_id", "session_id", "rep_id"]
predict_lock = Lock()


@lru_cache(maxsize=1)
def recordings():
    # shortcut: serve 20 bundled examples; add pagination when a larger browser is needed.
    labels = pd.read_csv(DATA_DIR / "labels.csv").head(20)
    result = {}
    for row in labels.to_dict("records"):
        key = (row["subject_id"], row["session_id"], row["rep_id"])
        result[key] = {"id": f"{key[0]}-{key[1]}-{key[2]}", "expected_label": row["form_label"], "exercise": row["exercise"], "source": "synthetic_dataset", "imu": [], "emg": []}
    for stream, filename in (("imu", "raw_imu.csv"), ("emg", "raw_emg.csv")):
        for chunk in pd.read_csv(DATA_DIR / filename, chunksize=100000):
            for key, group in chunk.groupby(KEYS, sort=False):
                if key in result:
                    result[key][stream].extend(group.drop(columns=KEYS).values.tolist())
    return {row["id"]: row for row in result.values()}


@asynccontextmanager
async def lifespan(app):
    app.state.predictor = FormPredictor()
    recordings()
    yield


app = FastAPI(title="WorkoutAI", lifespan=lifespan)
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"https?://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type"],
)

ImuRow = Annotated[list[FiniteFloat], Field(min_length=7, max_length=7)]
EmgRow = Annotated[list[FiniteFloat], Field(min_length=3, max_length=3)]


class RepetitionInput(BaseModel):
    model_config = ConfigDict(extra="forbid")
    exercise: Literal["bicep_curl"] = "bicep_curl"
    imu: Annotated[list[ImuRow], Field(min_length=2, max_length=5000)]
    emg: Annotated[list[EmgRow], Field(min_length=50, max_length=50000)]


@app.get("/health")
def health():
    return {"status": "ok", "model_loaded": True, "model_version": "cnn_lstm_v1", "metadata": app.state.predictor.metadata}


@app.get("/recordings")
def list_recordings():
    return [{k: v for k, v in row.items() if k not in ("imu", "emg")} for row in recordings().values()]


@app.get("/recordings/{recording_id}")
def get_recording(recording_id: str):
    row = recordings().get(recording_id)
    if row is None:
        raise HTTPException(404, "Recording not found.")
    return row


@app.post("/predict")
def predict(repetition: RepetitionInput):
    try:
        with predict_lock:
            return app.state.predictor.predict(repetition.imu, repetition.emg)
    except ValueError as error:
        raise HTTPException(422, str(error)) from error
