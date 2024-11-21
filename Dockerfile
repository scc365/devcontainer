ARG DEBIAN_VERSION=bookworm-slim
ARG MININET_REPO=https://github.com/mininet/mininet
ARG MININET_VERSION=2.3.0
ARG RYU_VERSION=4.34

FROM debian:${DEBIAN_VERSION} AS openflow
ARG MININET_REPO
ARG MININET_VERSION
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -q && \
    apt-get install -yq \
    autoconf \
    automake \
    libtool \
    make \
    gcc \
    git \
    autotools-dev \
    pkg-config \
    libc6-dev
WORKDIR /src/mininet
RUN git clone -b ${MININET_VERSION} ${MININET_REPO} .
ARG MININET_OF_REPO=https://github.com/mininet/openflow
WORKDIR /src/mnof
RUN git clone ${MININET_OF_REPO} ./openflow
RUN cp -R /src/mininet/util/openflow-patches/ openflow-patches/
WORKDIR /src/mnof/openflow
RUN patch -p1 < ../openflow-patches/controller.patch
RUN ./boot.sh && ./configure && make install


FROM debian:${DEBIAN_VERSION} AS mnexec
ARG MININET_REPO
ARG MININET_VERSION
RUN apt-get update -q && \
    apt-get install -yq gcc git
WORKDIR /src
RUN git clone -b ${MININET_VERSION} ${MININET_REPO} .
ARG MNEXEC_VERSION="latest"
RUN mkdir -p /output
RUN gcc -Wall -Wextra -DVERSION=\"\(${MNEXEC_VERSION}\)\" mnexec.c -o /output/mnexec


FROM debian:${DEBIAN_VERSION}
ARG MININET_REPO
ARG MININET_VERSION
ARG RYU_VERSION
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -q && \
    apt-get install --no-install-recommends -yqq \
    arping \
    curl \
    gcc \
    git \
    g++ \
    hping3 \
    iperf3 \
    iproute2 \
    iptables \
    iputils-ping \
    net-tools \
    openvswitch-common \
    openvswitch-switch \
    openvswitch-testcontroller \
    python3 \
    python3-bottle \
    python3-flask \
    python3-pip \
    python3-setuptools \
    telnet \
    tshark \
    traceroute && \
    rm -rf /var/lib/apt/lists/*
RUN pip install --break-system-packages eventlet==0.30.2 && \
    pip install --break-system-packages setuptools==59.5.0
RUN pip install --break-system-packages ryu==${RYU_VERSION}
COPY --from=openflow /usr/local/bin/ /usr/local/bin/
COPY --from=mnexec /output/mnexec /usr/bin/mnexec
WORKDIR /src/mininet
RUN git clone -b ${MININET_VERSION} ${MININET_REPO} .
RUN pip3 install --break-system-packages .
WORKDIR /
COPY scripts/start-ovs.sh /scripts/start-ovs.sh
RUN chmod +x /scripts/start-ovs.sh
WORKDIR /workspace
