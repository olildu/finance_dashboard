# Multi-stage build: frontend and backend.
# NOTE: This Dockerfile's build context is the REPO ROOT, not backend/.
# It COPYs both backend/ and frontend/ with paths relative to repo root.

FROM ghcr.io/cirruslabs/flutter:stable AS frontend-build
WORKDIR /app/frontend
COPY frontend/pubspec.* .
RUN flutter pub get
COPY frontend/ .
RUN flutter build web --release

FROM python:3.11-slim AS backend
WORKDIR /app
COPY backend/req.txt .
RUN pip install --no-cache-dir -r req.txt
COPY backend/ .
COPY --from=frontend-build /app/frontend/build/web ./static
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
