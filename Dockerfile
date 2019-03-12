# Use phusion/baseimage as base image. To make your builds reproducible, make
# sure you lock down to a specific version, not to `latest`!
# See https://github.com/phusion/baseimage-docker/blob/master/Changelog.md for
# a list of version numbers.
FROM phusion/baseimage:0.11

LABEL maintainer="owen.kaluza@monash.edu"
LABEL repo="https://github.com/OKaluza/LavaVu"

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

# ...put your own build instructions here...

# install things
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
        bash-completion \
        build-essential \
        git \
        python3 \
        python3-dev \
        python3-pip \
        xorg-dev \
        ssh \
        curl \
        libfreetype6-dev \
        libpng-dev \
        libtiff-dev \
        libxft-dev \
        xvfb \
        freeglut3 \
        freeglut3-dev \
        libgl1-mesa-dri \
        libgl1-mesa-glx \
        mesa-utils \
        libavcodec-dev \
        libavformat-dev \
        libavutil-dev \
        libswscale-dev \
        rsync \
        vim \
        less \
        xauth

RUN pip3 install --upgrade pip
RUN pip3 install setuptools
RUN pip3 install \
        packaging \
        appdirs \
        numpy \
        jupyter \
        matplotlib \
        runipy \
        pillow \
        scipy \
        h5py \
        rise \
        lavavu

#Setup RISE for notebook slideshows
RUN jupyter-nbextension install rise --py --sys-prefix

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir -p /etc/my_init.d

# script for xvfb-run.  all docker commands will effectively run under this via the entrypoint
#RUN printf "#\041/bin/sh \n rm -f /tmp/.X99-lock && Xvfb -screen 0 1600x1200x16 \$@\n" >> /etc/my_init.d/xvfb.sh

RUN printf "#\041/bin/sh \n killall Xvfb \nrm -f /tmp/.X99-lock && Xvfb -screen 0 1600x1200x16 & \njupyter notebook --no-browser --allow-root\n" >> /etc/my_init.d/xvfb.sh

RUN chmod +x /etc/my_init.d/xvfb.sh

# Add a notebook profile.
RUN mkdir -p -m 700 /root/.jupyter/ && \
    echo "c.NotebookApp.ip = '0.0.0.0'" >> /root/.jupyter/jupyter_notebook_config.py && \
    echo "c.NotebookApp.token = ''" >> /root/.jupyter/jupyter_notebook_config.py

WORKDIR /

# expose notebook port
EXPOSE 8888

# launch notebook
#CMD ["jupyter", "notebook", "--no-browser", "--allow-root"]
#CMD ["jupyter", "notebook", " --no-browser", "--allow-root", "--ip=0.0.0.0"]


