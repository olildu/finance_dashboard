# finance_dashboard

Personal finance dashboard: a FastAPI backend and a Flutter frontend.

## Structure

- `backend/` — FastAPI (Python) API. See `backend/req.txt` for dependencies and `backend/main.py` for the app entrypoint.
- `frontend/` — Flutter app. See `frontend/pubspec.yaml` for dependencies.
- `docker/` — containerized setup (coming soon).

## Getting started

### Backend
```
cd backend
pip install -r req.txt
uvicorn main:app --reload
```

### Frontend
```
cd frontend
flutter pub get
flutter run
```
