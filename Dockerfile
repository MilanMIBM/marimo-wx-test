# syntax=docker/dockerfile:1.12
FROM python:3.12-slim AS base
# Create a non-root user
RUN useradd -m appuser
WORKDIR /app
ARG marimo_version=0.11.26
ENV MARIMO_SKIP_UPDATE_CHECK=1
# Install uv and marimo
RUN pip install --no-cache-dir uv marimo==${marimo_version} && \
    mkdir -p /app/data && \
    chown -R appuser:appuser /app
ENV PORT=8080
EXPOSE $PORT
ENV HOST=0.0.0.0
# Install wxai requirements with uv (using --system flag)
RUN uv pip install --system altair pandas numpy && \
    uv pip install --system -r https://requirements-installs-bucket.s3.eu-de.cloud-object-storage.appdomain.cloud/marimo-requirements.txt
# Create uv cache directory for appuser and set package manager to uv
RUN mkdir -p /home/appuser/.config/marimo && \
    touch /home/appuser/.config/marimo/marimo.toml && \
    grep -q '\[package_management\]' /home/appuser/.config/marimo/marimo.toml || echo '[package_management]' >> /home/appuser/.config/marimo/marimo.toml && \
    grep -q 'manager' /home/appuser/.config/marimo/marimo.toml && sed -i 's/manager = .*/manager = "uv"/' /home/appuser/.config/marimo/marimo.toml || echo 'manager = "uv"' >> /home/appuser/.config/marimo/marimo.toml && \
    chown -R appuser:appuser /home/appuser
USER appuser
# Single entry point with sandbox mode
CMD marimo edit --sandbox --no-token -p $PORT --host $HOST
