#!/usr/bin/env bash

set -euo pipefail

ARCH=$1
VERSION="${2:-"25.04"}"

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

docker build --load --platform "linux/${ARCH}" --tag "axiphi/oakestra-vm-ubuntu:${VERSION}" --build-arg "VERSION=${VERSION}" .
