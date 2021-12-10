FROM amazon/aws-lambda-python:3.7 as base

# Install OS packages for Pillow-SIMD
RUN yum -y install tar gzip zlib freetype-devel \
    gcc \
    ghostscript \
    lcms2-devel \
    libffi-devel \
    libimagequant-devel \
    libjpeg-devel \
    libraqm-devel \
    libtiff-devel \
    libwebp-devel \
    make \
    openjpeg2-devel \
    rh-python36 \
    rh-python36-python-virtualenv \
    sudo \
    tcl-devel \
    tk-devel \
    tkinter \
    which \
    xorg-x11-server-Xvfb \
    zlib-devel \
    wget \
    make \
    && yum clean all

# Install libsndfile from source
RUN wget https://github.com/libsndfile/libsndfile/releases/download/1.0.31/libsndfile-1.0.31.tar.bz2
RUN tar -xf libsndfile-1.0.31.tar.bz2
RUN cd libsndfile-1.0.31 && ./configure
RUN cd libsndfile-1.0.31 && make
RUN cd libsndfile-1.0.31 && make install

# Install FFmpeg from source
RUN yum -y install autoconf automake bzip2 bzip2-devel cmake freetype-devel gcc gcc-c++ git libtool make pkgconfig zlib-devel
RUN mkdir ~/ffmpeg_sources

# NASM
RUN cd ~/ffmpeg_sources && wget https://www.nasm.us/pub/nasm/releasebuilds/2.15.05/nasm-2.15.05.tar.bz2
RUN cd ~/ffmpeg_sources && tar xjvf nasm-2.15.05.tar.bz2
RUN cd ~/ffmpeg_sources/nasm-2.15.05 && ./autogen.sh
RUN cd ~/ffmpeg_sources/nasm-2.15.05 && ./configure --prefix="/ffmpeg_build" --bindir="/bin"
RUN cd ~/ffmpeg_sources/nasm-2.15.05 && make 
RUN cd ~/ffmpeg_sources/nasm-2.15.05 && make install
RUN cd ~/ffmpeg_sources/nasm-2.15.05 && hash -d nasm

# Yasm
RUN cd ~/ffmpeg_sources && wget https://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz
RUN cd ~/ffmpeg_sources && tar xzvf yasm-1.3.0.tar.gz
RUN cd ~/ffmpeg_sources/yasm-1.3.0 && ./configure --prefix="/ffmpeg_build" --bindir="/bin"
RUN cd ~/ffmpeg_sources/yasm-1.3.0 && make
RUN cd ~/ffmpeg_sources/yasm-1.3.0 && make install

# ACC
RUN cd ~/ffmpeg_sources && git clone --depth 1 https://github.com/mstorsjo/fdk-aac
RUN cd ~/ffmpeg_sources/fdk-aac && autoreconf -fiv
RUN cd ~/ffmpeg_sources/fdk-aac && ./configure --prefix="/ffmpeg_build" --disable-shared
RUN cd ~/ffmpeg_sources/fdk-aac && make
RUN cd ~/ffmpeg_sources/fdk-aac && make install

# libmp3lame
RUN cd ~/ffmpeg_sources && wget https://downloads.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz
RUN cd ~/ffmpeg_sources && tar xzvf lame-3.100.tar.gz
RUN cd ~/ffmpeg_sources/lame-3.100 && ./configure --prefix="/ffmpeg_build" --bindir="/bin" --disable-shared --enable-nasm
RUN cd ~/ffmpeg_sources/lame-3.100 && make
RUN cd ~/ffmpeg_sources/lame-3.100 && make install

# Install FFMPEG
RUN cd ~/ffmpeg_sources && wget https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2
RUN cd ~/ffmpeg_sources && tar xjvf ffmpeg-snapshot.tar.bz2
RUN cd ~/ffmpeg_sources/ffmpeg && PATH="/bin:$PATH" PKG_CONFIG_PATH="/ffmpeg_build/lib/pkgconfig" ./configure \
  --prefix="/ffmpeg_build" \
  --pkg-config-flags="--static" \
  --extra-cflags="-I/ffmpeg_build/include" \
  --extra-ldflags="-L/ffmpeg_build/lib" \
  --extra-libs=-lpthread \
  --extra-libs=-lm \
  --bindir="/bin" \
  --enable-gpl \
  --enable-libfdk_aac \
  --enable-libfreetype \
  --enable-libmp3lame \
#   --enable-libopus \
#   --enable-libvpx \
#   --enable-libx264 \
#   --enable-libx265 \
  --enable-nonfree
RUN cd ~/ffmpeg_sources/ffmpeg && make
RUN cd ~/ffmpeg_sources/ffmpeg && make install
RUN cd ~/ffmpeg_sources/ffmpeg && hash -d ffmpeg

COPY ./requirements.txt ./

RUN pip install -r requirements.txt

# Replace Pillow with Pillow-SIMD to take advantage of AVX2
RUN pip uninstall -y pillow && CC="cc -mavx2" pip install -U --force-reinstall pillow-simd

RUN mkdir -m 777 /tmp/NUMBA_CACHE_DIR /tmp/MPLCONFIGDIR
ENV NUMBA_CACHE_DIR=/tmp/NUMBA_CACHE_DIR/
ENV MPLCONFIGDIR=/tmp/MPLCONFIGDIR/
