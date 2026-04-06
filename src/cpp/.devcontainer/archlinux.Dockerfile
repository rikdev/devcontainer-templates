FROM archlinux

ARG USER_NAME=user
ARG USER_UID=1000
ARG USER_GID=${USER_UID}

RUN <<EOF
    set -o errexit -o nounset -o pipefail

    groupadd --gid ${USER_GID} ${USER_NAME}
    useradd --uid ${USER_UID} --gid ${USER_GID} --create-home ${USER_NAME}
    # Add sudo support.
    pacman --sync --refresh --sysupgrade --noconfirm --needed sudo
    rm --recursive /var/{cache/pacman/pkg,lib/pacman/sync}/*
    echo ${USER_NAME} ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${USER_NAME}
    chmod 0440 /etc/sudoers.d/${USER_NAME}
EOF

RUN <<EOF
    set -o errexit -o nounset -o pipefail

    pacman --sync --refresh --sysupgrade --noconfirm

    # build tools
    pacman --sync --noconfirm --needed \
        clang \
        cmake \
        gcc \
        libc++ \
        lld \
        make \
        ninja \
        python \
        python-pip

    pip install --no-cache --break-system-packages conan

    # console utilities
    pacman --sync --noconfirm --needed \
        bash-completion \
        diffutils \
        gdb \
        git \
        git-lfs \
        less \
        lldb \
        openssh \
        vim

    rm --recursive /var/{cache/pacman/pkg,lib/pacman/sync}/*
EOF

USER ${USER_NAME}
