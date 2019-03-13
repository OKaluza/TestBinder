FROM python:3.7-slim

LABEL maintainer="owen.kaluza@monash.edu"
LABEL repo="https://github.com/OKaluza/LavaVu"

# install things
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
        bash-completion \
        build-essential \
        git \
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

# Add Tini
ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

# install the notebook package
RUN pip install --no-cache --upgrade pip && \
    pip install --no-cache notebook

RUN pip install setuptools
RUN pip install \
        packaging \
        appdirs \
        numpy \
        jupyter \
        notebook \
        matplotlib \
        runipy \
        pillow \
        scipy \
        h5py \
        rise

#RUN pip install lavavu
RUN pip install jupyter-server-proxy

RUN pip install jupyterlab

#Setup RISE for notebook slideshows
RUN jupyter-nbextension install rise --py --sys-prefix
RUN jupyter nbextension enable rise --py --sys-prefix

ENV NB_USER jovyan
ENV NB_UID 1000
ENV HOME /home/${NB_USER}

# create user with a home directory
ARG NB_USER
ARG NB_UID
ENV USER ${NB_USER}
ENV HOME /home/${NB_USER}

RUN adduser --disabled-password \
    --gecos "Default user" \
    --uid ${NB_UID} \
    ${NB_USER}
WORKDIR ${HOME}

# helper file for xvfb (for LavaVu)
ADD scripts/xvfb-run /usr/bin/
RUN chmod +x /usr/bin/xvfb-run
#ADD scripts/entrypoint.sh /usr/local/bin/entrypoint.sh

# script for xvfb-run.  all docker commands will effectively run under this via the entrypoint
RUN printf "#\041/bin/sh \n rm -f /tmp/.X99-lock && xvfb-run -s '-screen 0 1600x1200x16' \$@" >> /usr/local/bin/xvfbrun.sh && \
chmod +x /usr/local/bin/xvfbrun.sh

# Make sure the contents of our repo are in ${HOME}
COPY . ${HOME}
USER root
RUN chown -R ${NB_UID} ${HOME}
USER ${NB_USER}

#Install LavaVu dev version
# setup environment
ENV PYTHONPATH $PYTHONPATH:${HOME}/LavaVu

# get LavaVu, compile, delete some unnecessary files, trust notebooks, copy to home dir
RUN cd ~ && \
    git clone --branch "master" --single-branch https://github.com/OKaluza/LavaVu && \
    cd LavaVu && \
    #git checkout tags/v1.3.2 && \
    make LIBPNG=1 TIFF=1 VIDEO=1 -j$(nproc) && \
    rm -fr tmp

RUN cd ~ && \
    find LavaVu/notebooks -name \*.ipynb  -print0 | xargs -0 jupyter trust && \
    cp ${HOME}/LavaVu/notebooks/* ~

# Add a notebook profile.
RUN cd ~ && \
    mkdir .jupyter && \
    echo "c.NotebookApp.ip = '0.0.0.0'" >> .jupyter/jupyter_notebook_config.py && \
    echo "c.NotebookApp.token = ''" >> .jupyter/jupyter_notebook_config.py

# note we use xvfb which to mimic the X display for lavavu
ENTRYPOINT ["/tini", "--", "/usr/local/bin/xvfbrun.sh"]

# launch notebook
# CMD scripts/run-jupyter.sh
CMD ["jupyter", "notebook", "--ip='0.0.0.0'", "--NotebookApp.token='' ", "--no-browser"]

