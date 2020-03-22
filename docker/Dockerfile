FROM ubuntu:devel
RUN apt-get update && apt-get install -y \
	sudo
RUN useradd -m mike && \
    echo "mike:mike" | chpasswd && \
	adduser mike sudo && \
	chsh -s /bin/bash mike && \
	echo "mike ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/user && \
	echo "Set disable_coredump false" >> /etc/sudo.conf
USER mike
RUN sudo apt-get update && sudo apt-get install -y \
	build-essential \
	software-properties-common \
	vim \
	git \
	wget \
	curl \
	gdebi-core

RUN wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash && \\
	source ~/.profile && \\
	nvm install 13.11.0

RUN \curl -sSL https://get.rvm.io | bash && \\
	sudo usermod -a -G rvm mike && \\
	source  /home/mike/.rvm/scripts/rvm && \\
	rvm install ruby-2.7.0

RUN sudo apt-get install -y \
	redis \
	redis-tools && \\
	sudo service redis-server start

RUN sudo apt install -y \
	postgresql \
	postgresql-server-dev-12 \
	postgresql-client && \
	sudo service postgresql start

RUN git clone https://github.com/mikedalpee/Covid19Monitor.git
WORKDIR /home/mike/Covid19Monitor
RUN gem install bundler:2.1.4 && \
	bundle install

RUN wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
RUN sudo gdebi -n google-chrome-stable_current_amd64.deb