# Yosinski's caffe fork is based off of older CUDNN
FROM nvidia/cuda:7.5-cudnn4-devel-ubuntu14.04

# This is Trusty, so a lot of this stuff is out of date, esp. Python
# Make it minimal so that we can use conda's libs instead
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        cmake \
        git \
        wget \
        libatlas-base-dev \
        libboost-all-dev \
        libgtk2.0-dev \
        libhdf5-serial-dev \
    && rm -rf /var/lib/apt/lists/*

# Env vars
ENV HOME=/home/developer \
    CONDA_ROOT=/opt/conda \
    CAFFE_ROOT=/opt/caffe \
    DVTB_ROOT=/opt/dvtb \
    PATH=/opt/conda/bin:$PATH \
    uid=1000 gid=1000

# Make a "developer" user, conda is easier as non-root
RUN groupadd -g $gid developer && \
    useradd -N -m -d $HOME -u $uid -g $gid -s /bin/bash -c Developer developer && \
    echo "developer ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/developer && \
    chmod 0440 /etc/sudoers.d/developer && \
    mkdir -p $HOME $CONDA_ROOT $CAFFE_ROOT $DVTB_ROOT && \
    chown ${uid}:${gid} -R $HOME $CONDA_ROOT $CAFFE_ROOT $DVTB_ROOT

# Change to user
WORKDIR $HOME
USER developer

# Get Miniconda and install it into $CONDA_ROOT
# Also get older opencv that won't break everything (see issues on yosinski/caffe)
RUN wget https://repo.continuum.io/miniconda/Miniconda2-4.3.11-Linux-x86_64.sh && \
    echo "d573980fe3b5cdf80485add2466463f5 Miniconda2-4.3.11-Linux-x86_64.sh" | md5sum -c - && \
    bash Miniconda2-4.3.11-Linux-x86_64.sh -b -f -p $CONDA_ROOT && \
    rm Miniconda2-4.3.11-Linux-x86_64.sh && \
    conda update -y conda && \
    conda install -y --channel menpo opencv

# Move to $CAFFE_ROOT and get Yosinski's fork
WORKDIR $CAFFE_ROOT
RUN git clone --depth 1 https://github.com/BVLC/caffe.git . && \
    git remote add yosinski https://github.com/yosinski/caffe.git && \
    git fetch --all && \
    git checkout --track -b deconv-deep-vis-toolbox yosinski/deconv-deep-vis-toolbox

# Split out python-dateutil into its own requirements file because it's not on conda, 
# then use conda to install most of the packages and requirements, including the required
# system libraries (like protobuf, etc.)
# Also install pip because conda installs can coexist nicely with pip
RUN egrep 'python-dateutil' python/requirements.txt > python/requirements.pip.txt && \
    egrep -v 'python-dateutil' python/requirements.txt > python/requirements.conda.txt && \
    conda install -y --file=python/requirements.conda.txt \
        pip \
        curl \
        gflags \
        glog \
        leveldb \
        libprotobuf \
        libtiff \
        libpng \
        lmdb \
        protobuf \
        pydot \
        scikit-image \
        scipy \
        snappy \
    && pip install -r python/requirements.pip.txt

# We need to get the conda libs into the system (this will warn about truncated
# libraries, but hasn't been an issue so far)
RUN sudo bash -c "echo \"$CONDA_ROOT/lib\" > /etc/ld.so.conf.d/conda.conf && ldconfig"

# This version of caffe doesn't support nccl, but leave this here for later
# RUN git clone https://github.com/NVIDIA/nccl.git && cd nccl && make -j"$(nproc)" && sudo make install && cd .. && rm -rf nccl

# Not sure why, but we need a Makefile.config. This is mostly the same as
# Makefile.config.example in Yosinski's fork
COPY Makefile.config .

# Run cmake -- add all the include/lib support by hand, I welcome pull requests
# for this
RUN mkdir build && cd build && \
    cmake \
          -DGFLAGS_INCLUDE_DIR=$CONDA_ROOT/include \
          -DGFLAGS_LIBRARY=$CONDA_ROOT/lib \
          -DGLOG_INCLUDE_DIR=$CONDA_ROOT/include \
          -DGLOG_LIBRARY=$CONDA_ROOT/lib \
          -DLevelDB_INCLUDE=$CONDA_ROOT/include \
          -DLevelDB_LIBRARY=$CONDA_ROOT/lib \
          -DLMDB_INCLUDE_DIR=$CONDA_ROOT/include \
          -DLMDB_LIBRARIES=$CONDA_ROOT/lib \
          -DMKLROOT=$CONDA_ROOT \
          -DPROTOBUF_LIBRARY=$CONDA_ROOT/lib/libprotobuf.so \
          -DPROTOBUF_INCLUDE_DIR=$CONDA_ROOT/include \
          -DPROTOBUF_PROTOC_LIBRARY=$CONDA_ROOT/lib/libprotoc.so \
          -DPROTOBUF_PROTOC_EXECUTABLE=$CONDA_ROOT/bin/protoc \
          -DSNAPPY_ROOT_DIR=$CONDA_ROOT \
          -DUSE_CUDNN=1 ..
#           -DUSE_CUDNN=1 -DUSE_NCCL=1 ..
RUN make -j"$(nproc)"
RUN make -j"$(nproc)" pycaffe

# Update python stuff, redo ld.so cache
ENV PYCAFFE_ROOT=$CAFFE_ROOT/python \
    PYTHONPATH=$PYCAFFE_ROOT:$PYTHONPATH \
    PATH=$CAFFE_ROOT/build/tools:$PYCAFFE_ROOT:$PATH
RUN sudo bash -c "echo \"$CAFFE_ROOT/build/lib\" >> /etc/ld.so.conf.d/caffe.conf && ldconfig"

# Switch to $DVTB_ROOT, clone into location, and update caffe root because we can
WORKDIR $DVTB_ROOT
RUN git clone --depth 1 https://github.com/yosinski/deep-visualization-toolbox . && \
    sed -e"s,/path/to/caffe,${CAFFE_ROOT}," models/caffenet-yos/settings_local.template-caffenet-yos.py > settings_local.py

# Phew

