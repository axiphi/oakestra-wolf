#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<EOF
Usage: $(basename "$0") CONTAINER_ENGINE UBUNTU_VERSION PLATFORM [PLATFORM...]

Import Ubuntu cloud images and combine them into a local multi-architecture image.

Arguments:
  CONTAINER_ENGINE  Either "docker" or "podman"
  UBUNTU_VERSION    Ubuntu release, for example "26.04"
  PLATFORM          Docker platform string: linux/ARCH[/VARIANT]

Example:
  $(basename "$0") podman 26.04 linux/amd64 linux/arm64
EOF
}

if [[ ${1:-} == --help || ${1:-} == -h ]]; then
    usage
    exit 0
fi

if (( $# < 3 )); then
    usage >&2
    exit 2
fi

CONTAINER_ENGINE=$1
VERSION=$2
shift 2
PLATFORMS=("$@")

case "${CONTAINER_ENGINE}" in
    docker | podman) ;;
    *)
        echo "Unsupported container engine: ${CONTAINER_ENGINE}" >&2
        usage >&2
        exit 2
        ;;
esac

IMAGE="axiphi/oakestra-vm-ubuntu-raw:${VERSION}"
PLATFORM_IMAGES=()

for platform in "${PLATFORMS[@]}"; do
    IFS=/ read -r os arch variant extra <<< "${platform}"
    if [[ -z ${os} || -z ${arch} || -n ${extra} ]]; then
        echo "Invalid platform '${platform}'; expected linux/ARCH[/VARIANT]" >&2
        exit 2
    fi
    if [[ ${os} != linux ]]; then
        echo "Unsupported operating system '${os}' in platform '${platform}'" >&2
        exit 2
    fi
    case "${arch}" in
        amd64 | arm64) ;;
        *)
            echo "Unsupported Ubuntu cloud-image architecture: ${arch}" >&2
            exit 2
            ;;
    esac

    platform_image="${IMAGE}-${platform//\//-}"
    PLATFORM_IMAGES+=("${platform_image}")
    url="https://cloud-images.ubuntu.com/releases/${VERSION}/release/ubuntu-${VERSION}-server-cloudimg-${arch}-root.tar.xz"

    echo "Importing Ubuntu ${VERSION} ${platform} cloud image..."
    if [[ ${CONTAINER_ENGINE} == docker ]]; then
        docker import --platform "${platform}" "${url}" "${platform_image}"
    else
        variant_args=()
        if [[ -n ${variant} ]]; then
            variant_args=(--variant "${variant}")
        fi
        podman import \
            --os "${os}" \
            --arch "${arch}" \
            "${variant_args[@]}" \
            "${url}" "${platform_image}"
    fi
done

if [[ ${CONTAINER_ENGINE} == docker ]]; then
    platforms_csv=$(IFS=,; echo "${PLATFORMS[*]}")

    docker build \
        --platform "${platforms_csv}" \
        --build-arg "RAW_IMAGE=${IMAGE}" \
        --tag "${IMAGE}" \
        --file - \
        --load \
        . <<'EOF'
# Docker warns about global arguments used by FROM when they have no valid default.
ARG RAW_IMAGE
ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT
FROM ${RAW_IMAGE:-nowarn}-${TARGETOS:-nowarn}-${TARGETARCH:-nowarn}${TARGETVARIANT:+-${TARGETVARIANT}}
EOF
else
    podman manifest rm "${IMAGE}" 2>/dev/null || true
    podman manifest create "${IMAGE}" "${PLATFORM_IMAGES[@]}"
fi

echo "Created multi-architecture raw image ${IMAGE}"
