ARG FEDORA_MAJOR_VERSION=37

FROM ghcr.io/ublue-os/silverblue-main:${FEDORA_MAJOR_VERSION}

COPY etc /etc
COPY usr /usr

COPY --from=ghcr.io/ublue-os/config:latest /files/ublue-os-udev-rules /
COPY --from=ghcr.io/ublue-os/config:latest /files/ublue-os-update-services /
COPY --from=docker.io/mikefarah/yq /usr/bin/yq /usr/bin/yq

COPY ublue-firstboot /usr/bin
COPY recipe.yml /etc/ublue-recipe.yml

RUN setsebool -P -N use_nfs_home_dirs=1 unconfined_mozilla_plugin_transition=0 && \
    rpm-ostree override remove nano-default-editor && \
    echo "-- Installing RPMs defined in recipe.yml --" && \
    rpm_packages=$(yq '.rpms[]' < /etc/ublue-recipe.yml) && \
    for pkg in $rpm_packages; do \
        echo "Installing: ${pkg}" && \
        rpm-ostree install $pkg; \
    done && \
    echo "---" && \
    systemctl enable ratbagd.service && \
    systemctl enable rpm-ostree-countme.service && \
    sed -i 's/#DefaultTimeoutStopSec.*/DefaultTimeoutStopSec=15s/' /etc/systemd/user.conf && \
    sed -i 's/#DefaultTimeoutStopSec.*/DefaultTimeoutStopSec=15s/' /etc/systemd/system.conf && \
    rm -rf \
        /tmp/* \
        /var/* && \
    ostree container commit
