# FairCoin Node — Docker image
#
# Builds faircoind v3.0.0 from source and runs it in a container.

FROM debian:12-slim AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libtool \
    autotools-dev \
    autoconf \
    automake \
    pkg-config \
    bsdmainutils \
    python3 \
    libssl-dev \
    libevent-dev \
    libboost-all-dev \
    libdb5.3-dev \
    libdb5.3++-dev \
    libminiupnpc-dev \
    libzmq3-dev \
    ca-certificates \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
RUN git clone --depth 1 --branch main https://github.com/FairCoinOfficial/FairCoin.git .

RUN ./autogen.sh && \
    ./configure --without-gui --with-incompatible-bdb --disable-zmq && \
    make -j"$(nproc)" && \
    strip src/faircoind src/faircoin-cli src/faircoin-tx

# ---------- Runtime image ----------
FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    libssl3 \
    libevent-2.1-7 \
    libboost-system1.74.0 \
    libboost-filesystem1.74.0 \
    libboost-thread1.74.0 \
    libboost-program-options1.74.0 \
    libboost-chrono1.74.0 \
    libdb5.3++ \
    libminiupnpc17 \
    gosu \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /build/src/faircoind /usr/local/bin/faircoind
COPY --from=builder /build/src/faircoin-cli /usr/local/bin/faircoin-cli
COPY --from=builder /build/src/faircoin-tx /usr/local/bin/faircoin-tx

RUN useradd -r -m -d /home/faircoin -s /bin/bash faircoin

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

VOLUME ["/home/faircoin/.faircoin"]

EXPOSE 46372
EXPOSE 46373

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["faircoind", "-printtoconsole", "-server=1"]
