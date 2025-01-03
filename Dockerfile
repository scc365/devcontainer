ARG DEBIAN_VERSION=bookworm-slim
ARG MININET_REPO=https://github.com/mininet/mininet
ARG MININET_VERSION=2.3.0
ARG OSKEN_VERSION=2.11.2

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
ARG OSKEN_VERSION
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -yqq \
    gpg \
    wget
RUN mkdir -p /etc/apt/keyrings && \
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc |  gpg --dearmor -o /etc/apt/keyrings/gierens.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | tee /etc/apt/sources.list.d/gierens.list && \
    chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list && \
    apt-get update
RUN apt-get update -q && \
    apt-get install --no-install-recommends -yqq \
    arping \
    bat \
    curl \
    eza \
    figlet \
    gcc \
    git \
    gpg \
    g++ \
    hping3 \
    iperf3 \
    iproute2 \
    iptables \
    iputils-ping \
    libffi-dev \
    libssl-dev \
    libxml2-dev \
    libxslt1-dev \
    nano \
    net-tools \
    openvswitch-common \
    openvswitch-switch \
    openvswitch-testcontroller \
    python3 \
    python3-bottle \
    python3-dev \
    python3-flask \
    python3-pip \
    python3-setuptools \
    telnet \
    tshark \
    traceroute \
    vim \
    zlib1g-dev && \
    rm -rf /var/lib/apt/lists/*
COPY --from=openflow /usr/local/bin/ /usr/local/bin/
COPY --from=mnexec /output/mnexec /usr/bin/mnexec
RUN pip install --break-system-packages --upgrade pip
WORKDIR /src/mininet
RUN git clone -b ${MININET_VERSION} ${MININET_REPO} .
RUN pip3 install --break-system-packages .
WORKDIR /src/osken
RUN git clone -b ${OSKEN_VERSION} https://github.com/openstack/os-ken.git .
RUN pip install --break-system-packages -r requirements.txt && \
    python3 setup.py install
COPY scripts/*.sh /scripts/
RUN chmod +x /scripts/*.sh
WORKDIR /workspace
