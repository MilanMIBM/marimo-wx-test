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
# Create uv cache directory for appuser and root
RUN mkdir -p /home/appuser/.cache/uv && \
    mkdir -p /root/.cache/uv && \
    chown -R appuser:appuser /home/appuser

# Create pyproject.toml to override package manager setting
RUN echo '[tool.marimo.package_management]' > /app/pyproject.toml && \
    echo 'manager = "uv"' >> /app/pyproject.toml && \
    chown appuser:appuser /app/pyproject.toml

# Use a shell script as entrypoint to switch users dynamically
COPY --chmod=755 <<'EOF' /app/entrypoint.sh
#!/bin/sh
if [ "$USER_TYPE" = "root" ]; then
  echo "Running as root user"
  exec marimo edit --sandbox --no-token -p $PORT --host $HOST
else
  echo "Running as appuser"
  exec su -c "marimo edit --sandbox --no-token -p $PORT --host $HOST" appuser
fi
EOF

# Make script executable and set permissions
RUN chmod +x /app/entrypoint.sh && \
    chown root:root /app/entrypoint.sh

# Use the entrypoint script to determine user at runtime
ENTRYPOINT ["/app/entrypoint.sh"]
