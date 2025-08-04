ARG VERSION

FROM axiphi/oakestra-vm-ubuntu-raw:${VERSION}

RUN export DEBIAN_FRONTEND=noninteractive \
    && truncate --size 0 /etc/fstab \
    && apt-get update \
    && apt-get --yes purge cryptsetup \
    && apt-get --yes upgrade \
    && apt-get --yes install --no-install-recommends linux-virtual \
    && apt-get --yes autoremove \
    && apt-get --yes clean \
    && rm -rf /var/lib/apt/lists/*
