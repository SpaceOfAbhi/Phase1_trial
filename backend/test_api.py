import ast
from pathlib import Path

import numpy as np
import pandas as pd
import pytest
from fastapi.testclient import TestClient
from scipy.interpolate import interp1d

from .app import app
from .inference import prepare_repetition


@pytest.fixture(scope="module")
def client():
    with TestClient(app) as session:
        yield session


def test_real_saved_model_and_recording(client):
    assert client.get("/health").json()["model_loaded"] is True
    sample_id = client.get("/recordings").json()[0]["id"]
    recording = client.get(f"/recordings/{sample_id}").json()
    response = client.post("/predict", json={k: recording[k] for k in ("imu", "emg", "exercise")})
    assert response.status_code == 200, response.text
    output = response.json()
    assert output["predicted_class"] in output["probabilities"]
    assert sum(output["probabilities"].values()) == pytest.approx(1, abs=1e-5)
    assert np.asarray(output["features"]).shape == (256, 8)


def test_validation(client):
    assert client.post("/predict", json={"imu": [], "emg": []}).status_code == 422
    assert client.get("/recordings/missing").status_code == 404
    imu = [[0, 1, 2, 3, 4, 5, 6], [1, 1, 2, 3, 4, 5, 6]]
    emg = [[2 + i / 1000, 0.1, 0.2] for i in range(50)]
    assert client.post("/predict", json={"imu": imu, "emg": emg}).status_code == 422
    with pytest.raises(ValueError, match="strictly increasing"):
        prepare_repetition([imu[0], imu[0]], emg)
    with pytest.raises(ValueError, match="finite"):
        prepare_repetition([[0, float("nan"), 2, 3, 4, 5, 6], imu[1]], emg)


def test_preprocessing_matches_training():
    # Load only pure functions; importing train.py would start a training run.
    source = Path(__file__).resolve().parents[1] / "ML/train.py"
    tree = ast.parse(source.read_text())
    functions = [node for node in tree.body if isinstance(node, ast.FunctionDef)]
    names = [f"accelerometer_{axis}" for axis in "xyz"] + [f"gyroscope_{axis}" for axis in "xyz"]
    scope = {"np": np, "interp1d": interp1d, "IMU_FEATURES": names, "SEQUENCE_LENGTH": 256}
    exec(compile(ast.Module(body=functions, type_ignores=[]), str(source), "exec"), scope)
    imu = np.column_stack([np.linspace(0, 1, 101), np.random.default_rng(42).normal(size=(101, 6))])
    emg = np.column_stack([np.linspace(0, 1, 1001), np.random.default_rng(7).normal(size=(1001, 2))])
    _, aligned = scope["synchronize_repetition"](pd.DataFrame(imu, columns=["timestamp"] + names), pd.DataFrame(emg, columns=["timestamp", "biceps_emg", "triceps_emg"]))
    expected = scope["create_fixed_sequence"](aligned)
    np.testing.assert_allclose(prepare_repetition(imu, emg), expected, rtol=1e-6, atol=1e-6)
