FROM debian:testing

ARG USER_NAME=user
ARG USER_UID=1000
ARG USER_GID=${USER_UID}

RUN <<EOF
    set -eu

    groupadd --gid ${USER_GID} ${USER_NAME}
    useradd --uid ${USER_UID} --gid ${USER_GID} --create-home ${USER_NAME} --shell /bin/bash
    # Add sudo support.
    apt-get update
    apt-get install -y --no-install-recommends sudo
    rm -rf /var/lib/apt/lists/*
    echo ${USER_NAME} ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${USER_NAME}
    chmod 0440 /etc/sudoers.d/${USER_NAME}
EOF

USER ${USER_NAME}

RUN <<EOF
    set -eu

    sudo apt-get update

    # build tools
    sudo apt-get install -y --no-install-recommends \
        clang \
        clang-tools \
        cmake \
        g++ \
        libc++-dev \
        lld \
        make \
        ninja-build \
        python-is-python3 \
        python3-pip

    sudo pip install --no-cache --break-system-packages conan

    # console utilities
    sudo apt-get install -y --no-install-recommends \
        bash-completion \
        clang-format \
        gdb \
        git \
        git-lfs \
        less \
        lldb \
        locales \
        openssh-client \
        vim

    sudo sed --in-place 's/^# \(en_US\.UTF-8\)/\1/' /etc/locale.gen
    sudo locale-gen
    echo '. /usr/share/bash-completion/bash_completion' | sudo tee --append /etc/bash.bashrc

    sudo rm -rf /var/lib/apt/lists/*
EOF
