# syntax=docker/dockerfile:1
FROM nvidia/cuda:11.7.1-runtime-ubuntu20.04

ENV DEBIAN_FRONTEND=noninteractive
ARG CONDA_DIR="/opt/conda"
ENV PATH="$CONDA_DIR/bin:$PATH"
ARG TZ=Etc/UTC
ENV TZ=${TZ}

RUN apt-get update && \
  apt-get install -y wget fonts-dejavu-core rsync git libglib2.0-0 && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* && \
  wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
  /bin/bash ~/miniconda.sh -b -p /opt/conda && \
  rm ~/miniconda.sh && \
  echo ${PATH} && \
  conda install python=3.8.5 && conda clean -a -y && \
  git clone https://github.com/sd-webui/stable-diffusion-webui stable-diffusion && \
  cd stable-diffusion && \
  conda env update --file environment.yaml --name base && \
  conda clean -a -y && \
  cd / && \
  git clone https://github.com/hlky/sd-enable-textual-inversion.git sd-enable-textual-inversion && \
  cd sd-enable-textual-inversion && \
  rsync -a /sd-enable-textual-inversion/ /stable-diffusion/

WORKDIR /stable-diffusion

ENV TRANSFORMERS_CACHE=/cache/transformers TORCH_HOME=/cache/torch CLI_ARGS="" \
  GFPGAN_PATH=/stable-diffusion/src/gfpgan/experiments/pretrained_models/GFPGANv1.3.pth \
  RealESRGAN_PATH=/stable-diffusion/src/realesrgan/experiments/pretrained_models/RealESRGAN_x4plus.pth \
  RealESRGAN_ANIME_PATH=/stable-diffusion/src/realesrgan/experiments/pretrained_models/RealESRGAN_x4plus_anime_6B.pth

EXPOSE 7860

CMD \
  for path in "${GFPGAN_PATH}" "${RealESRGAN_PATH}" "${RealESRGAN_ANIME_PATH}"; do \
  name=$(basename "${path}"); \
  base=$(dirname "${path}"); \
  test -f "/models/${name}" && mkdir -p "${base}" && ln -sf "/models/${name}" "${path}" && echo "Mounted ${name}"; \
  done; \
  mkdir -p /cache/weights/ && \
  # run, -u to not buffer stdout / stderr
  python3 -u scripts/webui.py --outdir /output --ckpt /models/model.ckpt --save-metadata ${CLI_ARGS}