FROM rocker/rstudio:4.4
LABEL description="Rstudio server for single-cell sequencing analysis"
LABEL version="1.7"

MAINTAINER Songpeng Zu <zsp07@tsinghua.org>

ARG bioc_ver=3.19

RUN apt-get clean all && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
      libhdf5-dev \
      libcurl4-gnutls-dev \
      libssl-dev \
      libxml2-dev \
      libpng-dev \
      libxt-dev \
      zlib1g-dev \
      libbz2-dev \
      liblzma-dev \
      libglpk40 \
      libgit2-dev \
    && apt-get clean all && \
    apt-get purge && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN Rscript -e "install.packages(c('tidyverse', 'BiocManager', 'remotes', 'rmarkdown'))"
RUN Rscript -e "BiocManager::install(version = '${bioc_ver}')"
RUN Rscript -e "install.packages(c('SeuratObject', 'Seurat', 'here'))"

WORKDIR /home/rstudio
