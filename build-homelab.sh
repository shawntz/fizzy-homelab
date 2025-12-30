#!/bin/bash
# Build and push multi-architecture Fizzy Homelab Docker images
# This variant has signups disabled for homelab deployments

set -e

DOCKER_USERNAME="shawnschwartz"
IMAGE_NAME="fizzy-homelab"
TAG="${1:-latest}"

echo "Building Fizzy Homelab edition (signups disabled)"
echo "Target: ${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG}"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running. Please start Docker Desktop and try again."
    exit 1
fi

# Check if logged in to DockerHub
if ! docker info 2>/dev/null | grep -q "Username: ${DOCKER_USERNAME}"; then
    echo "Not logged in to DockerHub. Logging in..."
    docker login
fi

# Create and use a new buildx builder if it doesn't exist
if ! docker buildx ls | grep -q "multiarch-builder"; then
    echo "Creating multi-architecture builder..."
    docker buildx create --name multiarch-builder --use
else
    echo "Using existing multi-architecture builder..."
    docker buildx use multiarch-builder
fi

# Bootstrap the builder
docker buildx inspect --bootstrap

echo ""
echo "Building for linux/amd64 and linux/arm64..."
echo ""

# Build and push for both architectures
docker buildx build \
    --platform linux/amd64,linux/arm64 \
    --build-arg OCI_SOURCE=https://github.com/basecamp/fizzy \
    --build-arg OCI_DESCRIPTION="Fizzy Homelab Edition - Kanban tracking with signups disabled for private deployments" \
    --tag ${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG} \
    --push \
    .

echo ""
echo "✅ Successfully built and pushed multi-architecture images!"
echo ""
echo "Image available at: ${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG}"
echo "Supports: linux/amd64, linux/arm64"
echo ""
echo "To use:"
echo "  docker pull ${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG}"
echo ""
