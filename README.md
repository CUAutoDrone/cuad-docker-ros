# CUAD ROS Setup In Docker

This repository builds and uploads the Docker container for CUAD's ROS Setup

## How do I run this container?

In a terminal, run `docker run -it --rm -p 10000 ghcr.io/cuautodrone/cuad-ros:latest`.

If you want to make it such that the container is not deleted once you exit it, run `docker run -it -p 10000 ghcr.io/cuautodrone/cuad-ros:latest` instead.

Then, in a second terminal, run `docker ps` to find which port on your computer port 10000 in the container has been bound to.

To run GUI apps, go to `localhost:port` in a browser, where `port` is the port number.

If you need to run multiple GUI apps at once, and don't want to open a second terminal inside the container, you can run the first command with a `&` character at the end, which will cause it to run in the background.

## How do I build this container?

In the project directory, run `docker buildx bake --build-arg default.args.ROS_APT_SOURCE_VERSION=$(curl -s https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest | grep -F "tag_name" | awk -F\" '{print $4}')`.

Then, if you want to clear the build cache afterwards, run `docker buildx prune --all`.

## How do I use this repo?

Any new changes should first be tested by opening a Pull Request. All Pull Requests will be built and pushed to the `test` tag. Thus, if a Pull Request is already open, please do not open another one at the same time as it will overwrite the first pull request. Once the CI build is finished and you are ready to merge your changes, please add the `pr-pull` label to the PR before you merge it. This copies the image with the `test` tag to the `latest` tag, thus promoting the changes to the stable image.
