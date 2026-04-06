FROM debian:testing

ARG USER_NAME=user
ARG USER_UID=1000
ARG USER_GID=${USER_UID}

ENV LANG=C.UTF-8

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

RUN <<EOF
    set -eu

    apt-get update

    # build tools
    apt-get install -y --no-install-recommends \
        clang \
        clang-tidy \
        clang-tools \
        cmake \
        g++ \
        libc++-dev \
        lld \
        make \
        ninja-build \
        python-is-python3 \
        python3-pip

    pip install --no-cache --break-system-packages conan

    # console utilities
    apt-get install -y --no-install-recommends \
        bash-completion \
        clang-format \
        gdb \
        git \
        git-lfs \
        iproute2 \
        less \
        lldb \
        openssh-client \
        vim

    echo '. /usr/share/bash-completion/bash_completion' >> /etc/bash.bashrc

    rm -rf /var/lib/apt/lists/*
EOF

USER ${USER_NAME}
