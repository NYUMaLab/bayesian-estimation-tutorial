# IMAGE NAME: api/base/cpu
FROM python:3.7

ARG USER=malab

# Set up non-root user
RUN useradd -ms /bin/bash $USER
WORKDIR /home/$USER

# Args and environment variables
ENV PYTHON_VERSION="python3.7"

# Add repositories and update
#   If you need additional packages installed with sudo apt(-get),
#   add them here!
RUN apt-get -y update \
    && apt-get -y upgrade

RUN apt-get install -y \
    build-essential cmake curl gcc libgflags-dev  \
	nfs-common nmon pkg-config sphinx-common \
	software-properties-common unzip wget yasm zip zsh \
	libsm6 libxext6 libxrender-dev libssl-dev libpq-dev \
    && add-apt-repository ppa:ubuntu-toolchain-r/test \
    && apt-get update \
    && add-apt-repository ppa:git-core/ppa \
    && apt-get update \
    && apt-get install -y \
    git \
    libbz2-dev liblz4-dev libsnappy-dev libzstd-dev zlib1g-dev \
    libeigen3-dev graphviz
    && apt-get update -y \
    && apt-get upgrade -y \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /home/$USER

# Switch to user
USER $USER
WORKDIR /home/$USER

# Environment paths for Jupyter and ZSH
ENV ZSH_CUSTOM=/home/$USER/.zsh_custom
ENV JUPYTER_PATH=/home/$USER/.jupyter

# Set up virtual environment
ENV VENV_PATH=/home/$USER/bayes_tutorial
ENV PATH="$VENV_PATH/bin:$PATH"

# Set up ZSH
RUN mkdir $ZSH_CUSTOM \
	&& sh -c "$(wget -O- https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" \
	&& git clone https://github.com/denysdovhan/spaceship-prompt.git "$ZSH_CUSTOM/themes/spaceship-prompt" \
	&& ln -s "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "$ZSH_CUSTOM/themes/spaceship.zsh-theme" \
	&& echo "ZSH_CUSTOM=$ZSH_CUSTOM" >> /home/$USER/.zshrc \
	&& sed -i "s|ZSH_THEME=robbyrussell|ZSH_THEME=spaceship |g" /home/$USER/.zshrc

RUN $PYTHON_VERSION -m venv $VENV_PATH \
    && pip install -U pip \
    && pip install -r requirements.txt \
	&& rm requirements.txt

# Set up Jupyter notebook
RUN python -m ipykernel install --user --name research --display-name "research" \
    && jupyter notebook --generate-config \
    && openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
	-keyout $JUPYTER_PATH/notebook_key.key \
	-out $JUPYTER_PATH/notebook_cert.pem \
	-subj "/C=US/ST=NY/L=New York/O=Galbiati/OU=Research/CN=galbiati.github.io" \
	&& echo "c.NotebookApp.certfile = u'$JUPYTER_PATH/notebook_cert.pem'" >> $JUPYTER_PATH/jupyter_notebook_config.py \
    && echo "c.NotebookApp.keyfile = u'$JUPYTER_PATH/notebook_key.key'" >> $JUPYTER_PATH/jupyter_notebook_config.py \
    && echo "c.NotebookApp.ip = u'0.0.0.0'" >>$JUPYTER_PATH/jupyter_notebook_config.py \
    && echo "c.NotebookApp.port = 8000" >> $JUPYTER_PATH/jupyter_notebook_config.py \
    && echo "c.NotebookApp.open_browser = False" >> $JUPYTER_PATH/jupyter_notebook_config.py

# Expose port and run notebook
EXPOSE 8000

ENTRYPOINT ["jupyter", "notebook"]
