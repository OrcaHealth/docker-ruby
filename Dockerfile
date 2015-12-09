FROM phusion/baseimage:latest
MAINTAINER Orca Health <info@orcahealth.com>

ENV RUBY_MAJOR 2.2
ENV RUBY_VERSION 2.2.2
ENV TZ_PATH US/Mountain

# Install ruby dependencies.
RUN apt-get update -q \
    && apt-get install -qy \
      autoconf \
      build-essential \
      bison \
      libbz2-dev \
      libcurl4-openssl-dev \
      libevent-dev \
      libffi-dev \
      libglib2.0-dev \
      libncurses-dev \
      libreadline-dev \
      libssl-dev \
      libxml2-dev \
      libxslt-dev \
      libyaml-dev \
      ruby \
      zlib1g-dev \
      --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Install Rails dependencies.
RUN add-apt-repository ppa:mc3man/trusty-media
RUN apt-get update -q \
    && apt-get install -qy \
      ffmpeg \
      imagemagick \
      file \
      ghostscript \
      libpq-dev \
      nodejs \
      git \
      --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Some of ruby's build scripts are written in ruby. We purge this later
# to make sure our final image uses what we just built.
RUN mkdir -p /usr/src/ruby \
    && curl -SL "http://cache.ruby-lang.org/pub/ruby/$RUBY_MAJOR/ruby-$RUBY_VERSION.tar.bz2" \
      | tar -xjC /usr/src/ruby --strip-components=1 \
    && cd /usr/src/ruby \
    && autoconf \
    && ./configure --disable-install-doc \
    && make -j"$(nproc)" \
    && apt-get -y purge bison ruby \
    && apt-get autoremove -y \
    && make install \
    && rm -r /usr/src/ruby

# Set $PATH and install bundler.
ENV PATH vendor/bundle/bin:$PATH
RUN echo 'gem: --no-rdoc --no-ri' >> /etc/gemrc \
    && gem install bundler \
    && bundle config --global frozen 1

# Create project dir and configure permissions and Rails-required subdirs.
RUN mkdir -p /usr/src/app
RUN useradd -s /bin/bash -d /home/deploy -m deploy \
    && mkdir -p /usr/src/vendor/bundle \
    && bundle config path /usr/src/vendor/bundle \
    && chown -R deploy:deploy /usr/src \
    && mkdir /usr/src/app/tmp \
    && chown deploy:deploy /usr/src/app/tmp

# Set timezone.
RUN ln -fs /usr/share/zoneinfo/$TZ_PATH /etc/localtime

EXPOSE 8080
WORKDIR /usr/src/app
