FROM armhf/debian:stretch-slim
#FROM debian:stretch-slim AS buildstep
#FROM resin/raspberrypi3-debian:stretch AS buildstep
#FROM armhf/ubuntu:16.10 AS buildstep

WORKDIR /root

# common packages
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
    ca-certificates curl file \
    build-essential \
    binutils \
    autoconf automake autotools-dev libtool xutils-dev openssl && \
    rm -rf /var/lib/apt/lists/*

# install toolchain
RUN curl https://sh.rustup.rs -sSf | \
    sh -s -- --default-toolchain nightly -y

ENV PATH=/root/.cargo/bin:$PATH

RUN mkdir /.cargo

WORKDIR /rust
COPY . .
RUN cargo build -vv --release

#FROM armhf/ubuntu:16.10
FROM armhf/debian:stretch-slim
#FROM debian:stretch-slim
WORKDIR /root/

COPY --from=0 /rust/target/release .
CMD ["./multi-stage"]
