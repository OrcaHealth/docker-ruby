FROM orcahealth/baseimage:0.9.15
MAINTAINER Orca Health <info@orcahealth.com>

ENV RUBY_MAJOR 2.1
ENV RUBY_VERSION 2.1.5

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

# some of ruby's build scripts are written in ruby
# we purge this later to make sure our final image uses what we just built
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

# install things globally, for great justice
ENV GEM_HOME /usr/local/bundle
ENV PATH $GEM_HOME/bin:$PATH
ENV BUNDLE_APP_CONFIG $GEM_HOME

# don't create ".bundle" in all our apps
RUN echo 'gem: --no-rdoc --no-ri' >> "$HOME/.gemrc" \
    && gem install bundler \
  	&& bundle config --global path "$GEM_HOME" \
  	&& bundle config --global bin "$GEM_HOME/bin" \
    && bundle config --global frozen 1 \
    && chmod -R 755 $GEM_HOME
    # && chown -R :users $GEM_HOME

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

ONBUILD COPY Gemfile /usr/src/app/
ONBUILD COPY Gemfile.lock /usr/src/app/

ONBUILD COPY . /usr/src/app

EXPOSE 3000
CMD ["rails", "server"]
