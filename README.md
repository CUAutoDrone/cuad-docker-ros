# CUAD ROS Setup In Docker

This repository builds and uploads the Docker container for CUAD's ROS Setup

## How do I run this container?

In a terminal, run `docker run -it --rm -p 10000 ghcr.io/cuautodrone/cuad-ros:latest`.

If you want to make it such that the container is not deleted once you exit it, run `docker run -it -p 10000 ghcr.io/cuautodrone/cuad-ros:latest` instead.

Then, in a second terminal, run `docker ps` to find which port on your computer port 10000 in the container has been bound to.

To run GUI apps, go to `localhost:port` in a browser, where `port` is the port number.

If you need to run multiple GUI apps at once, and don't want to open a second terminal inside the container, you can run the first command with a `&` character at the end, which will cause it to run in the background.
