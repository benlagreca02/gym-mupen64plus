################################################################
FROM ubuntu:22.04 as base


# Setup environment variables in a single layer
ENV \
    # Prevent dpkg from prompting for user input during package setup
    DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    # mupen64plus will be installed in /usr/games; add to the $PATH
    PATH=$PATH:/usr/games \
    # Set default DISPLAY
    DISPLAY=:0


################################################################
FROM base AS buildstuff

# the stuff needed for build
RUN apt-get update && \
    apt-get install -y \
        build-essential \
        dpkg-dev \
        libwebkit2gtk-4.1-dev \
        libjpeg-dev \
        libtiff-dev \
        libgtk2.0-dev \
        libsdl1.2-dev \
        libgstreamer-plugins-base1.0-dev \
        libnotify-dev \
        freeglut3 \
        freeglut3-dev \
        libjson-c5 \
        libjson-c-dev \
        unzip \
        nasm \
        git

# clone, build, and install the input bot
# (explicitly specifying commit hash to attempt to guarantee behavior within this container)
# input plugin as verisoned before breaks with new version of mupen
WORKDIR /src/mupen64plus-src
# fetch the latest input plugin
RUN git clone https://github.com/mupen64plus/mupen64plus-core.git && \
        cd mupen64plus-core && \
        # git reset --hard 12d136dd9a54e8b895026a104db7c076609d11ff && \
        git pull && \
    cd .. && \
    git clone https://github.com/kevinhughes27/mupen64plus-input-bot.git && \
        cd mupen64plus-input-bot && \
        # git reset --hard 0a1432035e2884576671ef9777a2047dc6c717a2 && \
        git pull && \
    make all && \
    make install

################################################################
FROM base

# Update package cache and install dependencies
RUN apt-get update && \
    apt-get install -y \
        python3 python3-pip python3-setuptools python3-dev \
        wget \
        xvfb libxv1 x11vnc \
        imagemagick \
        nano \
        vim \
        ffmpeg \
        libjson-c5

# really could, and should do this in the build-executables layer thing?
# build requirements for mupen executable
RUN apt-get install -y \
        build-essential \
        libz-dev \
        libpng-dev \
        libsdl2-dev \
        libfreetype-dev \
        nasm \
        libboost-dev \
        gzip \
        git \
        libboost-filesystem-dev \
        libvulkan-dev 

# Upgrade pip (pip 21.0 dropped support for Python 2.7 in January 2021 - https://stackoverflow.com/a/65896996/9526448)
# TODO: Python3 upgrade - https://github.com/bzier/gym-mupen64plus/issues/81
RUN pip install --upgrade pip

# Install VirtualGL (provides vglrun to allow us to run the emulator in XVFB)
# (Check for new releases here: https://github.com/VirtualGL/virtualgl/releases)
ENV VIRTUALGL_VERSION=2.5.2
RUN wget "https://sourceforge.net/projects/virtualgl/files/${VIRTUALGL_VERSION}/virtualgl_${VIRTUALGL_VERSION}_amd64.deb" && \
    apt install ./virtualgl_${VIRTUALGL_VERSION}_amd64.deb && \
    rm virtualgl_${VIRTUALGL_VERSION}_amd64.deb

# Install dependencies (here for caching)
# just use latest for now, lock down version once dust has settled
# with migration to 22.04
RUN pip install \
    pyglet \
    gym \
    numpy \
    PyYAML \
    termcolor \
    mss \
    opencv-python

# Copy compiled input plugin from buildstuff layer
COPY --from=buildstuff /usr/local/lib/mupen64plus/mupen64plus-input-bot.so /usr/local/lib/mupen64plus/

# Copy the gym environment (current directory)
COPY . /src/gym-mupen64plus

# COPY ../mupen64plus-core-2.5.9.tar.gz /src/
# now install mupen, installing mupen from apt gives 2.5.0 version...
COPY ../m64p_helper_scripts.tar.gz /src/
RUN cd /src/ && \
    ls && \
    tar -xvzf /src/m64p_helper_scripts.tar.gz && \
    ./m64p_get.sh && ./m64p_build.sh && ./m64p_install.sh

# Copy the Super Smash Bros. save file to the mupen64plus save directory
# mupen64plus expects a specific filename, hence the awkward syntax and name
COPY [ "./gym_mupen64plus/envs/Smash/smash.sra", "/root/.local/share/mupen64plus/save/Super Smash Bros. (U) [!].sra" ]

# Install requirements & this package
WORKDIR /src/gym-mupen64plus
RUN python3 -m pip install -e .

# Declare ROMs as a volume for mounting a host path outside the container
VOLUME /src/gym-mupen64plus/gym_mupen64plus/ROMs/

WORKDIR /src

# Expose the default VNC port for connecting with a client/viewer outside the container
EXPOSE 5900
