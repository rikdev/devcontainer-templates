FROM debian:bookworm

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

    # build tools
    echo 'deb http://deb.debian.org/debian/ testing main' | sudo tee /etc/apt/sources.list.d/testing.list
    sudo apt-get update
    sudo apt-get install -y --no-install-recommends \
        clang-19 \
        cmake \
        g++-14 \
        libc++-19-dev \
        lld-19 \
        make \
        ninja-build \
        python-is-python3 \
        python3-pip

    sudo update-alternatives --install /usr/bin/clang clang /usr/bin/clang-19 0
    sudo update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-19 0
    sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-14 0
    sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-14 0

    sudo pip install --no-cache --break-system-packages conan

    # console utilities
    sudo apt-get install -y --no-install-recommends \
        bash-completion \
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
