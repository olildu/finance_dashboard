# finance_dashboard

Personal finance dashboard: a FastAPI backend and a Flutter frontend.

## Structure

- `backend/` — FastAPI (Python) API. See `backend/req.txt` for dependencies and `backend/main.py` for the app entrypoint.
- `frontend/` — Flutter app. See `frontend/pubspec.yaml` for dependencies.
- `docker-compose.yml` — containerized setup (Postgres + backend, serving the built Flutter web app).

## Getting started

### Docker (recommended)

Requires only Docker.

```
./scripts/setup.sh   # generates .env with random POSTGRES_PASSWORD / JWT_SECRET
docker compose up --build
```

App is served on `http://localhost:8000`.

### Native (backend + frontend separately)

Requires Python 3.11+ and Flutter (see `frontend/.fvm/fvm_config.json` for the pinned version).

```
./scripts/setup.sh   # generates .env if you don't already have one
```

#### Backend
```
cd backend
pip install -r req.txt
uvicorn main:app --reload
```

#### Frontend
```
cd frontend
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:8000/
```
Or use the VS Code launch configs in `.vscode/launch.json` / `frontend/.vscode/launch.json`, which already pass `API_BASE_URL`.
