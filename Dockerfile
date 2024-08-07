FROM ubuntu:22.04 as builder
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential cmake clang openssl libssl-dev zlib1g-dev gperf wget git ninja-build libsecp256k1-dev libsodium-dev libmicrohttpd-dev liblz4-dev pkg-config autoconf automake libtool libjemalloc-dev && \
	rm -rf /var/lib/apt/lists/*
ENV CC clang
ENV CXX clang++
ENV CCACHE_DISABLE 1

WORKDIR /
RUN mkdir ion
WORKDIR /ion

COPY ./ ./

RUN mkdir build && \
	cd build && \
	cmake -GNinja -DCMAKE_BUILD_TYPE=Release -DPORTABLE=1 -DTON_ARCH= -DTON_USE_JEMALLOC=ON .. && \
	ninja storage-daemon storage-daemon-cli tonlibjson fift func validator-engine validator-engine-console generate-random-id dht-server lite-client

FROM ubuntu:22.04
RUN apt-get update && \
    apt-get install -y wget libatomic1 openssl libsecp256k1-dev libsodium-dev libmicrohttpd-dev liblz4-dev libjemalloc-dev && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/ion-work/db && \
    mkdir -p /var/ion-work/db/static

COPY --from=builder /ion/build/storage/storage-daemon/storage-daemon /usr/local/bin/
COPY --from=builder /ion/build/storage/storage-daemon/storage-daemon-cli /usr/local/bin/
COPY --from=builder /ion/build/lite-client/lite-client /usr/local/bin/
COPY --from=builder /ion/build/validator-engine/validator-engine /usr/local/bin/
COPY --from=builder /ion/build/validator-engine-console/validator-engine-console /usr/local/bin/
COPY --from=builder /ion/build/utils/generate-random-id /usr/local/bin/

WORKDIR /var/ion-work/db
COPY ./docker/init.sh ./docker/control.template ./
RUN chmod +x init.sh

ENTRYPOINT ["/var/ion-work/db/init.sh"]