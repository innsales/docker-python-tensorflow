FROM python:3.8

COPY ./requirements.txt ./requirements.txt

RUN apt update
RUN apt -y install libsndfile-dev
RUN apt -y install ffmpeg

RUN pip install -r requirements.txt

RUN mkdir -m 777 /tmp/NUMBA_CACHE_DIR /tmp/MPLCONFIGDIR
ENV NUMBA_CACHE_DIR=/tmp/NUMBA_CACHE_DIR/
ENV MPLCONFIGDIR=/tmp/MPLCONFIGDIR/

RUN pip install awslambdaric
RUN pip install boto3