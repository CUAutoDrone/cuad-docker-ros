# CUAD ROS Setup In Docker

This repository builds and uploads the Docker container for CUAD's ROS Setup

## How do I run this container?

In a terminal, run `docker run -it --rm -p 10000 ghcr.io/cuautodrone/cuad-ros:latest`.

If you want to make it such that the container is not deleted once you exit it, run `docker run -it -p 10000 ghcr.io/cuautodrone/cuad-ros:latest` instead.

Then, in a second terminal, run `docker ps` to find which port on your computer port 10000 in the container has been bound to.

To run GUI apps, go to `localhost:port` in a browser, where `port` is the port number.

If you need to run multiple GUI apps at once, and don't want to open a second terminal inside the container, you can run the first command with a `&` character at the end, which will cause it to run in the background.

**Note:** The timezone in the container is hardcoded to `America/New_York`. If you want to change the timezone, run `sudo dpkg-reconfigure tzdata` in the container.

## How do I use my camera with this container?

First, run `mkfifo` to create a named pipe in a directory you plan on sharing with the container, using `mkfifo /path/to/named/pipe` where `/path/to/named/pipe` is the path to the named pipe you want to create (This probably won't work on Windows, I'm not sure how to created named pipes on Windows). Next, pass your camera to the named pipe using a command such as `ffmpeg -re -y -f avfoundation -framerate 30 -i "FaceTime HD Camera" -preset ultrafast -vcodec libx264 -tune zerolatency -vf mpdecimate,setpts=N/FRAME_RATE/TB -f h264 -flush_packets 0 - | pv -B 10000000 > /path/to/named/pipe`. You may have to replace the `-f avfoundation` and `-i "FaceTime HD Camera"` parts of the command with different values, which you can find by looking up "ffmpeg get input from camera" followed by your operating system (the above example is for a camera called "FaceTime HD Camera", which is the default name of the built-in camera on Mac Laptops, on macOS). Additionally, you may need to tweak the value passed to the `-B` parameter of `pv`. This value affects the size of the camera buffer (in bytes). Larger values may lead to more lag, but if the value is too small, the buffer can't even hold a full frame. The value above should work. Then, in your code, you should replace the `0` passed to `cv2.VideoCapture` with the path to your named pipe within the container, which should be enclosed in single quotes (for example, `cv2.VideoCapture('/home/user/HandGestureTest/camera')`). Additionally, when running the Docker Container, in order to share a local directory with the container, you should pass the `-v /path/on/host:/path/in/container` flag to `docker run`, where `/path/on/host` is the path on your computer that you want to share and `/path/in/container` is the path that you want the shared directory to be at in the container. 

## Help, Docker can't find the image or can't authenticate to the GitHub Container Registry

To fix this, you will have to authenticate Docker to the GitHub Container Registry. To do this, follow the instructions at [this link](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry#authenticating-with-a-personal-access-token-classic). However, I would recommend providing the PAT directly from your clipboard if possible so that it doesn't end up in your shell history. If you do this, do not run the command that has `export` in it. On macOS, one can paste from their clipboard by replacing `echo $CR_PAT` with `pbpaste`.

## How do I build this container?

In the project directory, run `docker buildx bake --build-arg default.args.ROS_APT_SOURCE_VERSION=$(curl -s https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest | grep -F "tag_name" | awk -F\" '{print $4}')`.

Then, if you want to clear the build cache afterwards, run `docker buildx prune --all`.

## How do I use this repo?

Any new changes should first be tested by opening a Pull Request. All Pull Requests will be built and pushed to the `test` tag. Thus, if a Pull Request is already open, please do not open another one at the same time as it will overwrite the first pull request. Once the CI build is finished and you are ready to merge your changes, please add the `pr-pull` label to the PR, which will automatically merge the PR at the end of the workflow. This copies the image with the `test` tag to the `latest` tag, thus promoting the changes to the stable image. Whenever a commit is pushed directly to the `main` branch, an image is built with
the `main` tag.

`.dockerbuild` files can be found in the build summaries from the `ci-pr` action.
