FROM orcahealth/base
MAINTAINER Orca Health <info@orcahealth.com>

ENV DEBIAN_FRONTEND noninteractive
ENV RUBY_INSTALL_VERSION 0.5.0
ENV RUBY_VERSION 2.1.3
ENV RUBY_BUILD_DEPENDENCIES build-essential autoconf automake pkg-config libffi-dev libgdbm-dev libreadline6-dev libssl-dev libyaml-dev
ENV COMMON_GEM_DEPENDENCIES libcurl4-gnutls-dev libxml2 libxslt1.1
ENV RUBY_PROFILE_PATH /etc/profile.d/ruby.sh

RUN echo 'gem: --no-document' > /etc/gemrc

RUN apt-get update -q \
    && apt-get install -qy $RUBY_BUILD_DEPENDENCIES --no-install-recommends

RUN cd /tmp \
    && wget -O ruby-install-$RUBY_INSTALL_VERSION.tar.gz https://github.com/postmodern/ruby-install/archive/v$RUBY_INSTALL_VERSION.tar.gz \
    && tar -xzvf ruby-install-$RUBY_INSTALL_VERSION.tar.gz \
    && cd ruby-install-$RUBY_INSTALL_VERSION/ \
    && make install \
    && ruby-install ruby $RUBY_VERSION --cleanup -- --disable-install-rdoc \

    && echo 'export PATH="$PATH:/opt/rubies/ruby-$RUBY_VERSION/bin"' > $RUBY_PROFILE_PATH \
    && chmod a+x $RUBY_PROFILE_PATH

ENV PATH $PATH:/opt/rubies/ruby-$RUBY_VERSION/bin

RUN gem install bundler \
    && gem update --system \

    && apt-get remove -y libssl-doc libtinfo-dev $RUBY_BUILD_DEPENDENCIES \
    && cd /var/lib/apt/lists \
    && rm -rf *Release* *Sources* *Packages* \
    && rm -rf /tmp/* \
    && truncate -s 0 /var/log/*log

# https://github.com/docker/docker/issues/4032
ENV DEBIAN_FRONTEND newt
