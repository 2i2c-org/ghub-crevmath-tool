#------------------------------------------------------------------------------------------------------------------------------
# Dockerfile to build a Docker image running the Ghub crevmath Jupyter notebook
#
# Component of: Ghub
# Purpose: Run a Ghub Jupyter Notebook
# Author: Renette Jones-Ivey
# Date: July 2026
#------------------------------------------------------------------------------------------------------------------------------

# ====================================================================
# System Installations
# ====================================================================

FROM anaconda-7_base_image:latest
    
LABEL desc="Ghub crevmath jupyter notebook docker image."

# ====================================================================
# User Configurations
# ====================================================================

# jovyan is the default user in Jupyter Docker Stacks containers. The term is a pun on "Jovian" (like Jupiter), coined to represent members of the Jupyter community.

# Set environment variables for Jupyter
ENV NB_USER=jovyan
ENV NB_UID=1000
ENV NB_GROUP=jovyan
ENV NB_GID=1000
ENV HOME=/home/${NB_USER}
ENV SHELL=/bin/bash

# Create the non-root user with UID 1000 and create the home directory
RUN groupadd --gid ${NB_GID} ${NB_GROUP} || true && \
    useradd --uid ${NB_UID} --gid ${NB_GID} --create-home ${NB_USER}

# ====================================================================
# Anaconda-7 Installations
# ====================================================================
USER root

# The version of the jupyterhub package installed must be the same version used by the main Hub. 
RUN . /home/anaconda/anaconda-7/bin/activate base && \
    python -m pip install --no-cache-dir jupyterhub==5.2.1 && \
    . /home/anaconda/anaconda-7/bin/deactivate

WORKDIR /home

COPY ./anaconda/install_conda_environment_and_kernel_from_yml.sh /home/anaconda/install_conda_environment_and_kernel_from_yml.sh
COPY ./anaconda/anaconda-7_earthaccess_environment.yml /home/anaconda/anaconda-7_earthaccess_environment.yml

WORKDIR /home/anaconda

# Install the earthaccess environment and kernel
RUN chmod +x install_conda_environment_and_kernel_from_yml.sh
RUN /bin/bash install_conda_environment_and_kernel_from_yml.sh anaconda-7 earthaccess

# ====================================================================
# Notebook Configurations
# ====================================================================

WORKDIR ${HOME}
COPY ./tools/crevmath ${HOME}/crevmath
RUN mkdir -p /${HOME}/.jupyter
#COPY ./containers/crevmath/config/jupyter_notebook_config.py ${HOME}/.jupyter/jupyter_notebook_config.py
RUN chown -R ${NB_USER}:${NB_GROUP} ${HOME}

# User setup
#RUN echo -e "${NB_USER} ALL=(ALL)       NOPASSWD:ALL\n" >> /etc/sudoers

USER ${NB_USER}

RUN jupyter trust ${HOME}/crevmath/crevmath.ipynb

WORKDIR ${HOME}/crevmath

# Set the command to run the single-user server when the container starts
CMD ["jupyterhub-singleuser"]
