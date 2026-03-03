#!/usr/bin/env bash
set -euo pipefail

# Activate Python venv
. atests/.venv/bin/activate || { echo "Missing atests/.venv. Run setup script first." >&2; exit 1; }

# Check if services are already running
SERVICES_WERE_RUNNING=false
if ./manage-services.sh check 2>/dev/null; then
    SERVICES_WERE_RUNNING=true
    echo "✅ Services already running"
else
    echo "🚀 Starting services for testing..."
    ./manage-services.sh start
fi

# Ensure cleanup on exit (only if we started the services)
cleanup() {
  if [ "$SERVICES_WERE_RUNNING" = false ]; then
    echo "🛑 Stopping services (restoring original state)..."
    ./manage-services.sh stop
  else
    echo "✅ Leaving services running (as they were before)"
  fi
}
trap cleanup EXIT

# Run tests
echo "🧪 Running Robot Framework tests..."
robot --outputdir atests/results atests/


