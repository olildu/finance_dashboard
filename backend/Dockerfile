# Multi-stage build: frontend and backend.
# NOTE: This Dockerfile's build context is the REPO ROOT, not backend/.
# It COPYs both backend/ and frontend/ with paths relative to repo root.

# No --platform pin here on purpose: FROM defaults to the build machine's
# native platform, which is what every real host (including arm64 cloud VMs)
# needs. On hosts where the arm64 build of this image is broken (e.g. Docker
# Desktop on Apple Silicon ships a corrupted/empty flutter launcher script at
# /sdks/flutter/bin/flutter), set `export DOCKER_DEFAULT_PLATFORM=linux/amd64`
# before building instead of pinning it here — that's a build-machine problem,
# not something the image should hardcode for every host.
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
