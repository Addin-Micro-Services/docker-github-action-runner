#!/bin/bash

set -e

# Check if required environment variables are set
if [ -z "$GITHUB_URL" ]; then
    echo "Error: GITHUB_URL environment variable is required"
    exit 1
fi

if [ -z "$GITHUB_TOKEN" ]; then
    echo "Error: GITHUB_TOKEN environment variable is required"
    echo "Get this token from GitHub Organization Settings -> Actions -> Runners -> Add runner"
    exit 1
fi

# Set default runner name if not provided
RUNNER_NAME=${RUNNER_NAME:-"docker-runner-$(hostname)"}

# Set default work directory
RUNNER_WORKDIR=${RUNNER_WORKDIR:-"_work"}

# Set default labels for organization runner
RUNNER_LABELS=${RUNNER_LABELS:-"docker,self-hosted,linux,org"}

# Configure the runner (following GitHub's official steps)
echo "Configuring GitHub Actions Organization Runner..."
echo "URL: $GITHUB_URL"
echo "Runner Name: $RUNNER_NAME"
echo "Labels: $RUNNER_LABELS"

# Remove any existing runner configuration
if [ -f ".runner" ]; then
    echo "Removing existing runner configuration..."
    ./config.sh remove --token "$GITHUB_TOKEN" || true
fi

# Create the runner and start the configuration experience (GitHub official step)
./config.sh \
    --url "$GITHUB_URL" \
    --token "$GITHUB_TOKEN" \
    --name "$RUNNER_NAME" \
    --work "$RUNNER_WORKDIR" \
    --labels "$RUNNER_LABELS" \
    --unattended \
    --replace

# Function to handle graceful shutdown
cleanup() {
    echo "Received shutdown signal. Removing runner..."
    ./config.sh remove --token "$GITHUB_TOKEN"
    exit 0
}

# Set up signal handlers for graceful shutdown
trap cleanup SIGTERM SIGINT

# Last step, run it! (GitHub official step)
echo "Starting GitHub Actions Runner..."
./run.sh &

# Wait for the background process
wait $!