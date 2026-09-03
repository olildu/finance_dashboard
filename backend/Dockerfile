# Multi-stage build: frontend and backend.
# NOTE: This Dockerfile's build context is the REPO ROOT, not backend/.
# It COPYs both backend/ and frontend/ with paths relative to repo root.

# FLUTTER_IMAGE_PLATFORM: on some arm64 hosts (e.g. Docker Desktop on Apple
# Silicon) the arm64 build of this image ships a corrupted/empty flutter
# launcher script (0 bytes) at /sdks/flutter/bin/flutter, so those hosts need
# --build-arg FLUTTER_IMAGE_PLATFORM=linux/amd64. On native arm64 Linux hosts
# (e.g. an ARM cloud VM), leave this unset — it defaults to BUILDPLATFORM
# (the build machine's own platform). Forcing amd64 there means running the
# Dart toolchain under QEMU emulation, which segfaults.
ARG BUILDPLATFORM
ARG FLUTTER_IMAGE_PLATFORM=${BUILDPLATFORM}
FROM --platform=${FLUTTER_IMAGE_PLATFORM} ghcr.io/cirruslabs/flutter:stable AS frontend-build
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
