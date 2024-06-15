#!/usr/bin/env bash

# Singularity uses /tmp, which is small on some of my servers
# Create and use a temp directory in ${HOME} instead
if [[ ! -d ${HOME}/tmp ]]; then
   mkdir ${HOME}/tmp
fi
export TMPDIR=$HOME/tmp

DOCKERHUB_VERSION=$(cat ./Singularity.def | grep "beyondpie/rstudio | cut -f3 -d':')

singularity build --fakeroot rstudio_server_verse_${DOCKERHUB_VERSION}.sif Singularity.def
