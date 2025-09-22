FROM ubuntu:22.04 AS main

LABEL name="cuad-ros"
LABEL org.opencontainers.image.authors="cuautodrone"

SHELL ["/bin/bash", "-c"]

RUN rm -f /etc/apt/apt.conf.d/docker-clean; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache

ARG TARGETARCH
ARG TARGETVARIANT

ARG GZ_SIM_SYSTEM_PLUGIN_PATH

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=cache-apt-$TARGETARCH-$TARGETVARIANT \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=lib-apt-$TARGETARCH-$TARGETVARIANT \
    apt update && apt dist-upgrade -y && apt autoclean

RUN locale

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=cache-apt-$TARGETARCH-$TARGETVARIANT \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=lib-apt-$TARGETARCH-$TARGETVARIANT \
    apt-get update && apt --no-install-recommends install -y locales

RUN locale-gen en_US en_US.UTF-8

RUN update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8

ENV LANG=en_US.UTF-8

RUN locale

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=cache-apt-$TARGETARCH-$TARGETVARIANT \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=lib-apt-$TARGETARCH-$TARGETVARIANT \
    apt-get update && apt --no-install-recommends install -y software-properties-common

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=cache-apt-$TARGETARCH-$TARGETVARIANT \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=lib-apt-$TARGETARCH-$TARGETVARIANT \
    add-apt-repository universe

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=cache-apt-$TARGETARCH-$TARGETVARIANT \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=lib-apt-$TARGETARCH-$TARGETVARIANT \
    apt-get update && apt --no-install-recommends install -y curl

ARG ROS_APT_SOURCE_VERSION

RUN curl -L -o /tmp/ros2-apt-source.deb "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.$(. /etc/os-release && echo ${UBUNTU_CODENAME:-${VERSION_CODENAME}})_all.deb"

RUN dpkg -i /tmp/ros2-apt-source.deb && rm /tmp/ros2-apt-source.deb

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=cache-apt-$TARGETARCH-$TARGETVARIANT \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=lib-apt-$TARGETARCH-$TARGETVARIANT \
    apt-get update && apt upgrade

ARG DEBIAN_FRONTEND=noninteractive

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=cache-apt-$TARGETARCH-$TARGETVARIANT \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=lib-apt-$TARGETARCH-$TARGETVARIANT \
    apt-get update && apt --no-install-recommends install -y ros-humble-desktop ros-dev-tools

ENV TZ=America/New_York

RUN ln -fs /usr/share/zoneinfo/$TZ /etc/localtime && dpkg-reconfigure -f noninteractive tzdata

RUN source /opt/ros/humble/setup.bash

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=cache-apt-$TARGETARCH-$TARGETVARIANT \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=lib-apt-$TARGETARCH-$TARGETVARIANT \
    apt-get update && apt --no-install-recommends install -y curl lsb-release gnupg

RUN curl https://packages.osrfoundation.org/gazebo.gpg --output /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg

RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] https://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/gazebo-stable.list

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=cache-apt-$TARGETARCH-$TARGETVARIANT \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=lib-apt-$TARGETARCH-$TARGETVARIANT \
    apt-get update && apt --no-install-recommends install -y gz-harmonic

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=cache-apt-$TARGETARCH-$TARGETVARIANT \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=lib-apt-$TARGETARCH-$TARGETVARIANT \
    apt-get update && apt --no-install-recommends install -y git gitk git-gui

ADD --keep-git-dir=true --chown=999 --link https://github.com/ArduPilot/ardupilot.git /ardupilot

WORKDIR /ardupilot

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=cache-apt-$TARGETARCH-$TARGETVARIANT \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=lib-apt-$TARGETARCH-$TARGETVARIANT \
    apt-get update && apt --no-install-recommends install -y sudo

RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

COPY --link <<"EOF" /etc/apt/apt.conf.d/01overrides
    APT::Install-Recommends "0";

EOF

RUN useradd --no-log-init -m -r -u 999 -g sudo user

USER user:sudo

ENV LANG=en_US.UTF-8

RUN source /opt/ros/humble/setup.bash

ENV USER=user

RUN Tools/environment_install/install-prereqs-ubuntu.sh -y

RUN . ~/.profile

ENV PATH=/home/user/.local/bin:$PATH

RUN Tools/autotest/sim_vehicle.py -v copter --console --map -w

RUN pip install --upgrade pymavlink MAVProxy --user

RUN gz sim -v4 -r shapes.sdf

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=cache-apt-$TARGETARCH-$TARGETVARIANT \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=lib-apt-$TARGETARCH-$TARGETVARIANT \
    sudo apt-get update && sudo apt --no-install-recommends install -y libgz-sim8-dev rapidjson-dev libopencv-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev gstreamer1.0-plugins-bad gstreamer1.0-libav gstreamer1.0-gl

WORKDIR /gz_ws/src

ADD --keep-git-dir=true --link https://github.com/ArduPilot/ardupilot_gazebo.git /gz_ws/src/ardupilot_gazebo

ENV GZ_VERSION=harmonic

WORKDIR /gz_ws/src/ardupilot_gazebo/build

RUN cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo

RUN make -j$(nproc)

ENV GZ_SIM_SYSTEM_PLUGIN_PATH=/gz_ws/src/ardupilot_gazebo/build:$GZ_SIM_SYSTEM_PLUGIN_PATH

ENV GZ_SIM_RESOURCE_PATH=/gz_ws/src/ardupilot_gazebo/models:/gz_ws/src/ardupilot_gazebo/worlds:GZ_SIM_RESOURCE_PATH

RUN gz sim -v4 -r iris_runway.sdf

RUN /ardupilot/Tools/autotest/sim_vehicle.py -v ArduCopter -f gazebo-iris --model JSON --map --console

ARG DEBIAN_FRONTEND=noninteractive

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=cache-apt-$TARGETARCH-$TARGETVARIANT \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=lib-apt-$TARGETARCH-$TARGETVARIANT \
    sudo apt-get update && sudo apt --no-install-recommends install -y xpra

RUN sudo rm -rf /var/lib/apt/lists/* /var/cache/apt/* /home/user/.cache/pip

RUN sudo rm /etc/apt/apt.conf.d/01overrides

ENV DISPLAY=:0

RUN xpra start --bind-tcp=0.0.0.0:10000

EXPOSE 10000