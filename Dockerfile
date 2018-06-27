FROM nvidia/cuda:8.0-cudnn6-devel-ubuntu16.04

MAINTAINER Igor Rabkin <igor.rabkin@xiaoyi.com>

ARG CAFFE_VERSION=1.0

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        git \
        wget \
        ssh-client \
        curl \
        nano \
        doxygen \
        libatlas-base-dev \
        libboost-all-dev \
        libgflags-dev \
        libgoogle-glog-dev \
        libhdf5-serial-dev \
        libleveldb-dev \
        liblmdb-dev \
        libopencv-dev \
        libprotobuf-dev \
        libsnappy-dev \
        protobuf-compiler \
        python-dev \
        python-numpy \
        python-pip \
        python-setuptools \
        python-scipy && \
    rm -rf /var/lib/apt/lists/*

ENV CAFFE_ROOT=/opt/caffe
WORKDIR $CAFFE_ROOT

################################
# Updating PIP and Dependences #
################################

RUN curl -fSsL -O https://bootstrap.pypa.io/get-pip.py && \
    python get-pip.py && \
    rm get-pip.py

RUN  pip uninstall python-dateutil && \
     wget https://pypi.python.org/packages/54/bb/f1db86504f7a49e1d9b9301531181b00a1c7325dc85a29160ee3eaa73a54/python-dateutil-2.6.1.tar.gz#md5=db38f6b4511cefd76014745bb0cc45a4 && \
     tar -xvf python-dateutil-2.6.1.tar.gz && \
     cd python-dateutil-2.6.1 && \
     python setup.py install && \
     cd .. && \
     rm -rf python-dateutil-2.6.1 python-dateutil-2.6.1.tar.gz

# Authorize SSH Host

RUN mkdir -p /root/.ssh && \
    chmod 0700 /root/.ssh

# Add the keys and set permissions

ADD ssh/id_rsa /root/.ssh/id_rsa
ADD ssh/known_hosts /root/.ssh/known_hosts
RUN chmod 400 /root/.ssh/id_rsa && \
    chmod 755 /root/.ssh/known_hosts

# Clonning & Installinf Caffe

RUN git clone ssh://git@server_1/media/CODE_CENTRAL/Caffe_1.0 . && \
    pip install --upgrade pip && \
    cd python && for req in $(cat requirements.txt) pydot; do pip install $req; done && cd .. && \
    mkdir build && cd build && \
    cmake -D CPU_ONLY=1 .. && \
    make -j"$(nproc)"

ENV PYCAFFE_ROOT $CAFFE_ROOT/python
ENV PYTHONPATH $PYCAFFE_ROOT:$PYTHONPATH
ENV PATH $CAFFE_ROOT/build/tools:$PYCAFFE_ROOT:$PATH
RUN echo "$CAFFE_ROOT/build/lib" >> /etc/ld.so.conf.d/caffe.conf && ldconfig

# Removing SSH TOKEN Keys:

RUN rm -rf /root/.ssh