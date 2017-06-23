FROM resin/raspberrypi3-debian:stretch AS buildstep

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

# Build cargo deps first, to improve caching
ADD Cargo.toml .
RUN mkdir src && touch src/lib.rs && cargo build --release --lib

# Bring in all source and build
COPY . .
RUN cargo build --release

FROM arm32v7/debian:stretch-slim

WORKDIR /root/

COPY --from=buildstep /rust/target/release/multi-stage multi-stage
ENV ROCKET_ENV=stage
CMD ["./multi-stage"]
