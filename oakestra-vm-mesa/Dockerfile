ARG VERSION

FROM axiphi/oakestra-vm-ubuntu:${VERSION} AS builder

RUN <<-EOT
	set -euxo pipefail
	export DEBIAN_FRONTEND=noninteractive

	# Enable source repositories and install Ubuntu's Mesa build dependencies.
	sed -i 's/^Types: deb$/Types: deb deb-src/' /etc/apt/sources.list.d/ubuntu.sources
	apt-get update
	apt-get --yes install --no-install-recommends apt-utils build-essential dpkg-dev
	apt-get --yes build-dep mesa

	# Add AMDGPU virtio support to Ubuntu's existing Mesa build configuration.
	mkdir /build
	cd /build
	apt-get source mesa
	cd mesa-*
	grep -q '^confflags_GALLIUM += -Dgallium-drivers=' debian/rules
	sed -i \
	    '/^confflags_GALLIUM += -Dgallium-drivers=/i confflags_GALLIUM += -Damdgpu-virtio=true' \
	    debian/rules

	# Build binary packages without running Mesa's tests or signing build artifacts.
	DEB_BUILD_OPTIONS=nocheck dpkg-buildpackage --build=binary --no-sign

	# Publish only the two modified runtime packages as a flat local APT repository.
	mkdir /repository
	cp \
	    /build/mesa-libgallium_*.deb \
	    /build/mesa-vulkan-drivers_*.deb \
	    /repository/
	cd /repository
	apt-ftparchive packages . > Packages
	apt-ftparchive \
	    -o APT::FTPArchive::Release::Origin="Oakestra" \
	    -o APT::FTPArchive::Release::Label="Oakestra Mesa" \
	    -o APT::FTPArchive::Release::Suite="oakestra" \
	    -o APT::FTPArchive::Release::Codename="oakestra" \
	    release . > Release
EOT

FROM axiphi/oakestra-vm-ubuntu:${VERSION}

COPY --from=builder /repository /usr/local/share/oakestra/apt/mesa

COPY <<-EOT /etc/apt/sources.list.d/00-oakestra-mesa.sources
	Types: deb
	URIs: file:/usr/local/share/oakestra/apt/mesa
	Suites: ./
	Trusted: yes
EOT

COPY <<-EOT /etc/apt/preferences.d/oakestra-mesa
	Package: mesa-libgallium mesa-vulkan-drivers
	Pin: release o=Oakestra
	Pin-Priority: 1001

	Package: mesa-libgallium mesa-vulkan-drivers
	Pin: version *
	Pin-Priority: -1
EOT

RUN <<-EOT
	set -euxo pipefail
	export DEBIAN_FRONTEND=noninteractive

	# Install the shadow packages selected by the Oakestra repository pin.
	apt-get update
	apt-get --yes install --no-install-recommends --reinstall \
	    mesa-libgallium mesa-vulkan-drivers
	apt-get --yes clean
	rm -rf /var/lib/apt/lists/*
EOT
