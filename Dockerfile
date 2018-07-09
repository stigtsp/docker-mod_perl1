FROM centos:7
MAINTAINER stig@stig.io

# Apache 1.3.42 with mod_perl 1.31 and perl 5.16.3 on Centos 7

# These packages are legacy software and should not be used for anything
# serious. Your computer might implode, catch fire or do other unexpected
# things. Consider yourself warned :)

# Based on:
#    https://github.com/THEMA-MEDIA/Act-out-of-the-box

# Patched versions from:
#   https://github.com/dhamidi/mod_perl-1.31
#   XXX: add 3rd apache patch

RUN yum -y --setopt=tsflags=nodocs update && \
    yum -y --setopt=tsflags=nodocs groupinstall "Development Tools" && \
    yum -y --setopt=tsflags=nodocs install wget git perl-devel perl-ExtUtils-Embed

# Hack needed by mod_perl1
RUN ln -s /usr/bin/xsubpp /usr/share/perl5/ExtUtils/xsubpp


#RUN apt-get update
#RUN apt-get --assume-yes install \
#    vim build-essential libgdbm-dev libperl-dev libgmp3-dev libfreetype6-dev \
#    libgif-dev libjpeg-dev libpng-dev libtiff-dev libpq-dev git tree
#RUN apt-get install -y wget

WORKDIR /installer


# Downloads
#
RUN wget https://archive.apache.org/dist/httpd/apache_1.3.42.tar.gz && \
  tar xf apache_1.3.42.tar.gz
RUN wget https://archive.apache.org/dist/httpd/libapreq/libapreq-1.34.tar.gz && \
  tar xf libapreq-1.34.tar.gz
RUN git clone https://github.com/dhamidi/mod_perl-1.31 && \
  cd mod_perl-1.31 && git reset --hard e9c3c41cee42d2c86d052f4f8628a85a0788e717 # head, sticky

RUN wget http://cpanmin.us -O /usr/local/bin/cpanm && chmod a+x /usr/local/bin/cpanm

# 
RUN yum -y install perl-CGI perl-libwww

# Apache: 1.3.42 and a dhamidi/mod_perl that seems to compile with perl 5.16.3
#
# Apache Patches from:
#    THEMA-MEDIA/Act-out-of-the-box, contains additonal patch XXX.

ADD apache_1.3.42.patch /installer/apache_1.3.42.patch
RUN patch -p0 < apache_1.3.42.patch
RUN cd mod_perl-1.31 && perl Makefile.PL APACHE_SRC=../apache_1.3.42/src DO_HTTPD=1 USE_APACI=1 EVERYTHING=1 APACI_ARGS=--enable-module=so && \
  make && make test && make install

RUN cd apache_1.3.42 && make install
RUN cpanm --notest Apache::Test

# libapreq
#
RUN cd libapreq-1.34 && perl Makefile.PL && make && make install

CMD /usr/local/apache/bin/httpd -X

