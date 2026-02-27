FROM ubuntu:24.04 AS build-wxpython

ARG TARGETARCH
ARG TARGETVARIANT

RUN apt-get update && apt --no-install-recommends install -y python3-pip

RUN pip download -U -f https://extras.wxpython.org/wxPython4/extras/linux/gtk3/ubuntu-24.04 wxpython

RUN ls *.whl || (apt-get update && apt --no-install-recommends install -y python3-venv gettext dos2unix lsb-release sudo && mkdir wxpython && tar xzf wxpython* -C wxpython --strip-components=1 && python3 -m venv venv && source venv/bin/activate && pip install --upgrade pip setuptools wheel && cd wxpython && python -m pip install --upgrade requirements.txt && ./buildtools/install_depends.txt && cd .. && WXPYTHON_BUILD_ARGS="--release" pip wheel -v wxpython*.tar.gz)

ARG BUILDKIT_SBOM_SCAN_STAGE=true
FROM ubuntu:24.04 AS main

LABEL name="cuad-ros"
LABEL org.opencontainers.image.authors="cuautodrone"

SHELL ["/bin/bash", "-c"]

RUN rm -f /etc/apt/apt.conf.d/docker-clean; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache

ARG TARGETARCH
ARG TARGETVARIANT

ARG GZ_SIM_SYSTEM_PLUGIN_PATH

ARG GZ_SIM_RESOURCE_PATH

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
    apt-get update && apt --no-install-recommends install -y ros-dev-tools

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=cache-apt-$TARGETARCH-$TARGETVARIANT \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=lib-apt-$TARGETARCH-$TARGETVARIANT \
    apt-get update && apt upgrade -y

ARG DEBIAN_FRONTEND=noninteractive

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=cache-apt-$TARGETARCH-$TARGETVARIANT \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=lib-apt-$TARGETARCH-$TARGETVARIANT \
    apt-get update && apt --no-install-recommends install -y ros-jazzy-desktop

ENV TZ=America/New_York

RUN ln -fs /usr/share/zoneinfo/$TZ /etc/localtime && dpkg-reconfigure -f noninteractive tzdata

RUN source /opt/ros/jazzy/setup.bash

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=cache-apt-$TARGETARCH-$TARGETVARIANT \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=lib-apt-$TARGETARCH-$TARGETVARIANT \
    apt-get update && apt --no-install-recommends install -y curl lsb-release gnupg

RUN curl https://packages.osrfoundation.org/gazebo.gpg --output /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg

RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] https://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/gazebo-stable.list

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=cache-apt-$TARGETARCH-$TARGETVARIANT \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=lib-apt-$TARGETARCH-$TARGETVARIANT \
    apt-get update && apt --no-install-recommends install -y cppzmq-dev gz-harmonic && apt-mark auto cppzmq-dev

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

RUN source /opt/ros/jazzy/setup.bash

ENV USER=user

ARG AP_DOCKER_BUILD=1

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=cache-apt-$TARGETARCH-$TARGETVARIANT \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=lib-apt-$TARGETARCH-$TARGETVARIANT \
    --mount=type=cache,target=/home/user/.cache/pip,sharing=shared,id=cache-pip \
    Tools/environment_install/install-prereqs-ubuntu.sh -y

ARG AP_DOCKER_BUILD=0

RUN . ~/.profile

ENV PATH=/home/user/.local/bin:$PATH

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=cache-apt-$TARGETARCH-$TARGETVARIANT \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=lib-apt-$TARGETARCH-$TARGETVARIANT \
    sudo apt-get update && sudo apt --no-install-recommends install -y python3-pip

COPY --from=build-wxpython *.whl /

RUN --mount=type=cache,target=/home/user/.cache/pip,sharing=shared,id=cache-pip \
    mv /*.whl /home/user/.cache/pip/

RUN --mount=type=cache,target=/home/user/.cache/pip,sharing=shared,id=cache-pip \
    PATH=/home/user/venv-ardupilot/bin:$PATH pip install --upgrade pymavlink MAVProxy --user

RUN PATH=/home/user/venv-ardupilot/bin:$PATH Tools/autotest/sim_vehicle.py -v copter --console --map -w

RUN PATH=/home/user/venv-ardupilot/bin:$PATH gz sim -v4 -r shapes.sdf

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=cache-apt-$TARGETARCH-$TARGETVARIANT \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=lib-apt-$TARGETARCH-$TARGETVARIANT \
    sudo apt-get update && sudo apt --no-install-recommends install -y libgz-sim8-dev rapidjson-dev libopencv-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev gstreamer1.0-plugins-bad gstreamer1.0-libav gstreamer1.0-gl

WORKDIR /gz_ws/src

ADD --keep-git-dir=true --link https://github.com/ArduPilot/ardupilot_gazebo.git /gz_ws/src/ardupilot_gazebo

ENV GZ_VERSION=harmonic

WORKDIR /gz_ws/src/ardupilot_gazebo/build

RUN PATH=/home/user/venv-ardupilot/bin:$PATH cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo

RUN PATH=/home/user/venv-ardupilot/bin:$PATH make -j$(nproc)

RUN echo 'export GZ_SIM_SYSTEM_PLUGIN_PATH=/gz_ws/src/ardupilot_gazebo/build:${GZ_SIM_SYSTEM_PLUGIN_PATH}' >> /home/user/.bashrc

RUN echo 'export GZ_SIM_RESOURCE_PATH=/gz_ws/src/ardupilot_gazebo/models:/gz_ws/src/ardupilot_gazebo/worlds:${GZ_SIM_RESOURCE_PATH}' >> /home/user/.bashrc

ENV GZ_SIM_SYSTEM_PLUGIN_PATH=/gz_ws/src/ardupilot_gazebo/build:$GZ_SIM_SYSTEM_PLUGIN_PATH

ENV GZ_SIM_RESOURCE_PATH=/gz_ws/src/ardupilot_gazebo/models:/gz_ws/src/ardupilot_gazebo/worlds:$GZ_SIM_RESOURCE_PATH

RUN PATH=/home/user/venv-ardupilot/bin:$PATH gz sim -v4 -r iris_runway.sdf

RUN PATH=/home/user/venv-ardupilot/bin:$PATH /ardupilot/Tools/autotest/sim_vehicle.py -v ArduCopter -f gazebo-iris --model JSON --map --console

RUN rm -f /gz_ws/src/ardupilot_gazebo/build/qemu*

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=cache-apt-$TARGETARCH-$TARGETVARIANT \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=lib-apt-$TARGETARCH-$TARGETVARIANT \
    sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt --no-install-recommends install -y geographiclib-tools libgeographiclib26

ADD --link https://raw.githubusercontent.com/mavlink/mavros/master/mavros/scripts/install_geographiclib_datasets.sh /home/user/

RUN sudo bash /home/user/install_geographiclib_datasets.sh

RUN sudo geographiclib-get-geoids egm96-5

RUN sudo geographiclib-get-magnetic wmm2020

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=cache-apt-$TARGETARCH-$TARGETVARIANT \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=lib-apt-$TARGETARCH-$TARGETVARIANT \
    sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt --no-install-recommends install -y libasio-dev libgeographiclib-dev

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=cache-apt-$TARGETARCH-$TARGETVARIANT \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=lib-apt-$TARGETARCH-$TARGETVARIANT \
    sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt --no-install-recommends install -y ros-jazzy-mavros ros-jazzy-mavros-extras

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=cache-apt-$TARGETARCH-$TARGETVARIANT \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=lib-apt-$TARGETARCH-$TARGETVARIANT \
    sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt --no-install-recommends install -y xpra

RUN sudo chown -R user:sudo /home/user

RUN sudo chmod -R 750 /home/user

RUN sudo rm -rf /var/lib/apt/lists/* /var/cache/apt/* /home/user/.cache/pip

RUN sudo rm /etc/apt/apt.conf.d/01overrides

ENV DISPLAY=:0

RUN echo 'source /opt/ros/jazzy/setup.bash' >> /home/user/.bashrc

RUN echo 'ps cax | grep xpra >/dev/null || xpra start --bind-tcp=0.0.0.0:10000 2>/dev/null' >> /home/user/.bashrc

WORKDIR /home/user

EXPOSE 10000