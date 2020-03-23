FROM ubuntu:devel
SHELL ["/bin/bash", "-c"]
ENV TZ=America/New_York
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt-get update && apt-get install -y \
    apt-utils \
    locales \
	sudo
RUN useradd -m mike && \
    echo "mike:mike" | chpasswd && \
	adduser mike sudo && \
	chsh -s /bin/bash mike && \
	echo "mike ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/user && \
	echo "Set disable_coredump false" >> /etc/sudo.conf && \
	locale-gen en_US.UTF-8 && \
    update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8

USER mike
WORKDIR /home/mike

RUN sudo apt-get update && sudo apt-get install -y \
	build-essential \
	software-properties-common \
	vim \
	git \
	wget \
	curl \
	gdebi-core

RUN wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash && \
    source /home/mike/.nvm/nvm.sh; nvm install 13.11.0

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list && \
    sudo apt update && sudo apt install --no-install-recommends yarn

RUN \curl -sSL https://get.rvm.io | bash && \
    echo "export SECRET_KEY_BASE=4da13406d9e1323919197c5d29c89c4c06f85ef1e6d3abce8c84d29fca2f39123029e46847f3a05fa8055c412a3925c303a2f3e1cde94418c2c69cd2de3fc4e4" >> /home/mike/.bashrc && \
    echo "export RAILS_ENV=production" >> /home/mike/.bashrc && \
    echo "export RUBYOPT=-\"W:no-deprecated -W:no-experimental\"" >> /home/mike/.bashrc && \
    echo "source /home/mike/.rvm/scripts/rvm" >> /home/mike/.bashrc
RUN source /home/mike/.rvm/scripts/rvm; rvm install ruby-2.7.0

RUN sudo apt-get install -y \
	redis \
	redis-tools &&

RUN sudo apt-get install -y \
    postgresql \
	postgresql-server-dev-12 \
	postgresql-client

RUN mkdir /home/mike/Covid19Monitor && \
    git clone https://github.com/mikedalpee/Covid19Monitor.git

WORKDIR /home/mike/Covid19Monitor
RUN source /home/mike/.rvm/scripts/rvm; gem install bundler:2.1.4; bundle install && \
    yarn install --check--files

WORKDIR /home/mike/Covid19Monitor/db/snapshot
RUN sudo cp pg_hba.conf postgresql.conf /etc/postgresql/12/main && \
    sudo service postgresql start && \
	./restore_db.sh

WORKDIR /home/mike

RUN wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    sudo gdebi -n ./google-chrome-stable_current_amd64.deb