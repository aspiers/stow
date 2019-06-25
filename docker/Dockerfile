# Build docker image: `docker build -t stowtest`
# Run tests: (from stow src directory)
#    `docker run --rm -it -v $(pwd):$(pwd) -w $(pwd) stowtest`
FROM debian:jessie
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
