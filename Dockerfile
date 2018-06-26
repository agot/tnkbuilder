# build-env
FROM debian:buster AS build-env
MAINTAINER ago

# install base packages
RUN apt-get update \
 && apt-get install -y gcc g++ sudo curl git cmake apt-transport-https libboost-all-dev libssl-dev libwebsocketpp-dev libcpprest-dev

# copy source
ARG SRC_DIR=src/
COPY ${SRC_DIR} src

WORKDIR src
RUN cmake -DCMAKE_INSTALL_PREFIX=/opt . \
 && make -j4 \
 && make install

FROM debian:buster-slim AS execute-env
MAINTAINER ago

RUN apt-get update \
 && apt-get install -y libssl1.1 libboost-system1.62.0 libcpprest2.10 \
 && apt-get clean

RUN useradd -m -d /home/tnkserv tnkserv
USER tnkserv
WORKDIR /home/tnkserv

COPY --from=build-env /opt /opt
ENTRYPOINT ["/opt/bin/tnkserv"]
