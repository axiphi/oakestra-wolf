#!/usr/bin/env bash

set -euo pipefail

ARCH=$1
VERSION="${2:-"25.04"}"

echo "Importing ubuntu cloud image..."
curl \
    --proto '=https' \
    --tlsv1.2 \
    --silent \
    --show-error \
    --fail \
    --location \
    "https://cloud-images.ubuntu.com/releases/${VERSION}/release/ubuntu-${VERSION}-server-cloudimg-${ARCH}-root.tar.xz" \
  | xzcat \
  | docker import --platform "linux/${ARCH}" - "axiphi/oakestra-vm-ubuntu-raw:${VERSION}"
echo "Imported ubuntu cloud image"

echo "Building ubuntu VM base image..."
docker buildx build --load --platform "linux/${ARCH}" --tag "axiphi/oakestra-vm-ubuntu:${VERSION}" --build-arg "VERSION=${VERSION}" .
echo "Built ubuntu VM base image"
