Now available as a docker-hub pull:

    $ docker pull fishcorn/dvtb-container
    $ [NV_GPU=<your_gpu_id>] nvidia-docker run -ti \
      --name dvtb \
      -e DISPLAY \
      -v /tmp/.X11-unix:/tmp/.X11-unix \
      -v /path/to/a/workspace:/home/developer/work \
      fishcorn/dvtb-container

Note that the `developer` user has `uid:gid == 1000:1000`, which will map to the current user for most single-user Debian/Ubuntu systems, but for other uid/gid combinations you'd have to rebuild the image (see below). 

I know there are ways to remap the uid/gid, but I just haven't included one because of time. Feel free to issue a pull request to enable this though.

# dvtb-container
This is a docker container that encapsulates all of the annoying steps to get yosinski/deep-visualization-toolbox working.

See http://yosinski.com/deepvis for general information, along with a video, and https://github.com/yosinski/deep-visualization-toolbox for the actual software. 

This container is mostly to get things working easily, and will let you run this with X windows, even though it's in a container. The last bit is enabled with ideas from [this excellent blog post by Fábio Rehm](http://fabiorehm.com/blog/2014/09/11/running-gui-apps-with-docker/).

Change Dockerfile so that the uid and gid match yours, then build this container with 

    $ nvidia-docker build -t <name_or_tag> .

Run this container with 

    $ [NV_GPU=<your_gpu_id>] nvidia-docker run -ti \
      --name dvtb \
      -e DISPLAY \
      -v /tmp/.X11-unix:/tmp/.X11-unix \
      -v /path/to/a/workspace:/home/developer/work \
      <name_or_tag>
      
Again, thanks to Fábio Rehm for doing the X Windows groundwork.

I welcome pull requests to get this working better/more efficiently.
