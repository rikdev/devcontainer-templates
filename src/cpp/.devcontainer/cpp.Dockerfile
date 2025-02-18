FROM archlinux

ARG USER_NAME=user
ARG USER_UID=1000
ARG USER_GID=${USER_UID}

RUN <<EOF
    groupadd --gid ${USER_GID} ${USER_NAME}
    useradd --uid ${USER_UID} --gid ${USER_GID} --create-home ${USER_NAME}
    # Add sudo support.
    pacman --sync --refresh --sysupgrade --noconfirm --needed sudo
    rm --recursive /var/{cache/pacman/pkg,lib/pacman/sync}/*
    echo ${USER_NAME} ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${USER_NAME}
    chmod 0440 /etc/sudoers.d/${USER_NAME}
EOF

USER ${USER_NAME}

RUN <<EOF
    # build tools
    sudo pacman --sync --refresh --sysupgrade --noconfirm
    sudo pacman --sync --noconfirm --needed \
        clang \
        cmake \
        gcc \
        libc++ \
        lld \
        make \
        ninja \
        python \
        python-pip

    sudo pip install --no-cache --break-system-packages conan

    # console utilities
    sudo pacman --sync --noconfirm --needed --noconfirm\
        bash-completion \
        gdb \
        git \
        git-lfs \
        less \
        lldb \
        openssh \
        vim

    sudo rm --recursive /var/{cache/pacman/pkg,lib/pacman/sync}/*
EOF
