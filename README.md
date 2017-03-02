# dvtb-container
This is a docker container that encapsulates all of the annoying steps to get yosinski/deep-visualization-toolbox working.

See http://yosinski.com/deepvis for general information, along with a video, and https://github.com/yosinski/deep-visualization-toolbox for the actual software. This container is mostly to get things working easily, and will let you run this with X windows. The last bit is enabled with ideas from [this excellent blog post by Fábio Rehm](http://fabiorehm.com/blog/2014/09/11/running-gui-apps-with-docker/).

Build this container with 

    $ nvidia-docker build <name_or_tag> .

Run this container with 

    $ NV_GPU=1 nvidia-docker run -ti \
      --name dvtb \
      -e DISPLAY=$DISPLAY \
      -v /tmp/.X11-unix:/tmp/.X11-unix \
      -v /path/to/a/workspace:/home/developer/work \
      <name_or_tag>
      
Again, thanks to Fábio Rehm for doing the X Windows groundwork.

I welcome pull requests to get this working better/more efficiently.
