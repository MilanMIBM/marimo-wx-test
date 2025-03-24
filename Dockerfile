# syntax=docker/dockerfile:1.12
FROM python:3.12-slim AS base

# Create a non-root user
RUN useradd -m appuser

WORKDIR /app

ARG marimo_version=0.11.26
ENV MARIMO_SKIP_UPDATE_CHECK=1

# Install essential packages
RUN pip install --no-cache-dir marimo==${marimo_version} && \
    mkdir -p /app/data && \
    chown -R appuser:appuser /app

ENV PORT=8080
EXPOSE $PORT
ENV HOST=0.0.0.0

# Install wxai requirements
RUN pip install --no-cache-dir altair pandas numpy && \
    pip install --no-cache-dir -r https://requirements-installs-bucket.s3.eu-de.cloud-object-storage.appdomain.cloud/marimo-requirements.txt

# Set up virtual environment for appuser
RUN pip install --no-cache-dir virtualenv && \
    mkdir -p /home/appuser/venv && \
    chown -R appuser:appuser /home/appuser/venv

USER appuser

# Create virtual environment and add to PATH
RUN virtualenv /home/appuser/venv && \
    echo 'export PATH="/home/appuser/venv/bin:$PATH"' >> /home/appuser/.bashrc

# Single entry point that uses wxai configuration
CMD . /home/appuser/venv/bin/activate && marimo edit --no-token -p $PORT --host $HOST
