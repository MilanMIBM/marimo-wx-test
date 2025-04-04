# syntax=docker/dockerfile:1.4
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

# Install requirements with uv (using --system flag)
RUN uv pip install --system altair pandas numpy && \
    uv pip install --system -r https://requirements-installs-bucket.s3.eu-de.cloud-object-storage.appdomain.cloud/marimo-requirements.txt

# Create uv cache directory for appuser 
RUN mkdir -p /home/appuser/.cache/uv && \
    chown -R appuser:appuser /home/appuser

USER appuser

# Single entry point with sandbox mode using shell form for environment variable expansion
CMD marimo edit --sandbox --no-token -p $PORT --host $HOST
