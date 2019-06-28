# This file is part of GNU Stow.
#
# GNU Stow is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# GNU Stow is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see https://www.gnu.org/licenses/.

# Build docker image: `docker build -t stowtest`
# Run tests: (from stow src directory)
#    `docker run --rm -it -v $(pwd):$(pwd) -w $(pwd) stowtest`
FROM debian:jessie
RUN printf "deb http://archive.debian.org/debian/ jessie main\ndeb-src http://archive.debian.org/debian/ jessie main\ndeb http://security.debian.org jessie/updates main\ndeb-src http://security.debian.org jessie/updates main" > /etc/apt/sources.list
RUN DEBIAN_FRONTEND=noninteractive \
apt-get update -qq && \
apt-get install -y -q \
    autoconf \
    bzip2 \
    cpanminus \
    gawk \
    git \
	libssl-dev \
    make \
	patch \
    perlbrew \
    texinfo \
    texlive \
    texi2html \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/*

# Set up perlbrew
ENV HOME=/root \
    PERLBREW_ROOT=/usr/local/perlbrew \
    PERLBREW_HOME=/root/.perlbrew \
    PERLBREW_PATH=/usr/local/perlbrew/bin
RUN mkdir -p /usr/local/perlbrew /root \
    && perlbrew init \
	&& perlbrew install-cpanm \
	&& perlbrew install-patchperl \
    && perlbrew install-multiple -j 4 --notest \
        perl-5.22.2 \
        perl-5.20.3 \
        perl-5.18.4 \
        perl-5.16.3 \
        perl-5.14.4 \
&& perlbrew clean

# Bootstrap the perl environments
COPY ./bootstrap-perls.sh /bootstrap-perls.sh
RUN /bootstrap-perls.sh && rm /bootstrap-perls.sh

# Add test script to container filesystem
COPY ./run-stow-tests.sh /run-stow-tests.sh

ENTRYPOINT ["/run-stow-tests.sh"]
