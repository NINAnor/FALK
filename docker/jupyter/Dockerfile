# The image to use as a base image
FROM quay.io/uninett/jupyter-spark:20190814-a51cd1c

# Based on:
# https://github.com/mundialis/docker-grass-gis/blob/master/Dockerfile
# https://github.com/OSGeo/grass/blob/master/docker/Dockerfile_alpine_wxgui
# 

LABEL authors="Stefan Blumentrath"
LABEL maintainer="stefan.blumentrath@nina.no"

# PACKAGES VERSIONS
ARG GRASS_VERSION=7.9
ARG PYTHON_VERSION=3
ARG PROJ_VERSION=5.2.0
ARG PROJ_DATUMGRID_VERSION=1.8

# Set environmental variables for GRASS GIS compilation, without debug symbols
ENV MYCFLAGS="-O2 -std=gnu99 -m64" \
    MYLDFLAGS="-s -Wl,--no-undefined -lblas" \
    # CXX stuff:
    LD_LIBRARY_PATH="/usr/local/lib" \
    LDFLAGS="$MYLDFLAGS" \
    CFLAGS="$MYCFLAGS" \
    CXXFLAGS="$MYCXXFLAGS" \
    NUMTHREADS=2



# Install system packages
USER root

WORKDIR /tmp

# Workaround for resolveconf ubuntu docker issue
# https://stackoverflow.com/questions/40877643/apt-get-install-in-ubuntu-16-04-docker-image-etc-resolv-conf-device-or-reso
RUN echo "resolvconf resolvconf/linkify-resolvconf boolean false" | debconf-set-selections

# Install the dependencies of GRASS GIS (we'll locally compile PROJ 4.9)
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install software-properties-common -y && \
    add-apt-repository ppa:ubuntugis/ubuntugis-unstable -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

    RUN apt-get update && \
    apt-get install --no-install-recommends --no-install-suggests -y \
    attr \
    bc \
    bison \
    build-essential \
    bzip2 \
    curl \
    cython \
    flex \
    g++ \
    gcc \
    gdal-bin \
    geany \
    gettext \
    git \
    gnutls-bin \
    ipython3 \
    libapt-pkg-perl \
    libboost-system-dev \
    libboost-thread-dev \
    libboost-filesystem-dev \
    libboost-program-options-dev \
    libboost-iostreams-dev \
    libbz2-dev \
    libcairo2 \
    libcairo2-dev \
    libcitygml-bin \
    libcitygml-dev \
    libcurl4-gnutls-dev \
    libdap-dev \
    libfftw3-bin \
    libfftw3-dev \
    libfreetype6-dev \
    libgdal-dev \
    libgeos-dev \
    libgnutls28-dev \
    libglu1-mesa-dev \
    libgsl0-dev \
    libjpeg-dev \
    liblas-c-dev \
    liblas-dev \
    liblapack-dev \
    libnetcdf-dev \
    libncurses5-dev \
    libopenjp2-7 \
    libopenjp2-7-dev \
    libpdal-dev pdal \
    libpdal-plugin-python \
    libpng-dev \
    libpnglite-dev \
    libpq-dev \
    libpython3-all-dev \
    libproj-dev \
    libqgis-dev \
    libreadline-dev \
    libsqlite3-dev \
    libspatialite-dev \
    libtiff-dev \
    libxmu-dev \
    libzstd-dev \
    libgeotiff-dev \
    libzstd-dev \
    make \
    mc \
    moreutils \
    ncurses-bin \
    netcdf-bin \
    p7zip-full \
    # python3-argparse-manpage \
    python3-dateutil \
    python3-dev \
    python3-extras \
    python3-fiona \
    python3-gdal \
    python3-geopandas \
    python3-httplib2 \
    python3-igraph \
    python3-jinja2 \
    python3-libxml2 \
    python3-mysqldb \
    python3-otb \
    python3-owslib \
    #python3-pdal \
    python3-pep8 \
    python3-pillow \
    python3-pil \
    python3-pip \
    python3-matplotlib \
    python3-netcdf4 \
    python3-numpy \
    python3-osmapi \
    python3-overpass \
    python3-overpy \
    python3-pandas \
    python3-pydap \
    python3-rasterio \
    python3-requests \
    python3-rpy2 \
    python3-scipy \
    python3-shapely \
    python3-sklearn \
    python3-simplejson \
    python3-sip \
    python3-six \
    python3-sqlalchemy \
    python3-tk \
    python3-unittest2 \
    python3-urllib3 \
    python3-xlsxwriter \
    python3-xlrd \
    python3-yaml \
    postgresql \
    proj-bin \
    proj-data \
    sqlite3 \
    subversion \
    unixodbc-dev \
    unzip \
    vim \
    virtualenv \
    wget \
    xterm \
    python3-setuptools cython3 \
    zlib1g-dev qgis saga libsaga-dev python-saga rasterio libsfcgal-dev spatialite-gui \
    shapelib libshp-dev gmt fiona octave-mapping \
    otb-bin libotb-dev otb-qgis libotb-apps libgdal-dev gdal-bin \
    qgis python3-qgis qgis-plugin-grass && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN echo LANG="en_US.UTF-8" > /etc/default/locale

RUN pip3 install \
    #psutil \
    cartopy \
    folium \
    # iris \
    pysal \
    scikit-learn \
    grass-session \
    pymodis \
    pystan \
    pymc3 \
    sentinelsat \
    threddsclient \
    pandas \
    pygbif \
    gbif

# unpack source code package and remove tarball archive:
RUN mkdir /opt/src
WORKDIR /opt/src
RUN git clone https://github.com/OSGeo/grass.git grass_build
WORKDIR /opt/src/grass_build

# Set environmental variables for GRASS GIS compilation, without debug symbols
ENV MYCFLAGS "-O2 -std=gnu99 -m64"
ENV MYLDFLAGS "-s -Wl,--no-undefined"
# CXX stuff:
ENV LD_LIBRARY_PATH "/usr/local/lib"
ENV LDFLAGS "$MYLDFLAGS"
ENV CFLAGS "$MYCFLAGS"
ENV CXXFLAGS "$MYCXXFLAGS"

# Fixup python shebangs - TODO: will be resolved in future by grass-core
WORKDIR /opt/src/grass_build
# RUN find -name '*.py' | xargs sed -i 's,#!/usr/bin/env python,#!/usr/bin/env python3,'
# RUN sed -i 's,python,python3,' include/Make/Platform.make.in

# Configure compile and install GRASS GIS
ENV GRASS_PYTHON=/usr/bin/python3
ENV NUMTHREADS=4
RUN make distclean || echo "nothing to clean"
RUN /opt/src/grass_build/configure \
    --enable-largefile \
    --with-ffmpeg --with-ffmpeg-includes="/usr/include/ffmpeg /usr/include/ffmpeg/libav* /usr/include/ffmpeg/libpostproc /usr/include/ffmpeg/libswscale" \
    --with-cxx \
    --with-blas \
    --with-lapack \
    --with-proj --with-proj-share=/usr/share/proj \
    --with-gdal=/usr/bin/gdal-config \
    --with-geos \
    --with-sqlite \
    --with-bzlib \
    --with-liblas \
    --with-zstd \
    --with-cairo --with-cairo-ldflags=-lfontconfig \
    --with-fftw \
    --with-liblas \
    --with-pdal \
    --with-netcdf \
    --with-postgres --with-postgres-includes="/usr/include/postgresql" \
    --with-freetype --with-freetype-includes=/usr/include/freetype2 \
    --with-openmp \
    --with-opengl \
    --without-nls \
    --without-mysql \
    --with-odbc \
    --with-readline \
    --with-wxwidgets=/usr/bin/wx-config \
    && make -j $NUMTHREADS

RUN make install && ldconfig

# enable simple grass command regardless of version number
RUN ln -s `find /usr/local/bin -name "grass*"` /usr/local/bin/grass

WORKDIR $HOME

# Unset environmental variables to avoid later compilation issues
ENV INTEL ""
ENV MYCFLAGS ""
ENV MYLDFLAGS ""
ENV MYCXXFLAGS ""
ENV LD_LIBRARY_PATH ""
ENV LDFLAGS ""
ENV CFLAGS ""
ENV CXXFLAGS ""

# set SHELL var to avoid /bin/sh fallback in interactive GRASS GIS sessions in docker
ENV SHELL /bin/bash

# System python kernel now already available in the base application
#COPY jupyter/systempy.sh /opt/src/
#RUN /bin/bash /opt/src/systempy.sh

# Clean up the compiled files
RUN rm -rf /opt/src/*

# Reduce the image size
RUN apt-get autoremove -y
RUN apt-get clean -y

USER notebook
