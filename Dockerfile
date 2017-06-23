#FROM resin/raspberrypi3-debian:stretch AS buildstep
FROM resin/raspberrypi3-node:6.10-20170623 AS buildstep

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

# Build cargo deps first, to improve caching.
COPY Cargo.toml .
RUN mkdir src && touch src/lib.rs && cargo build --release --lib

# Install webpack and reactjs deps.
COPY package.json .
RUN npm install

# Bring in all source and build
COPY . .
RUN cargo build --release
RUN node_modules/webpack/bin/webpack.js


####################
# Runtime Container
####################
FROM arm32v7/debian:stretch-slim

WORKDIR /root/

# copy the rust binary
COPY --from=buildstep /rust/target/release/multi-stage multi-stage

# copy the static frontend assets.
COPY --from=buildstep /rust/static/ static/

ENV ROCKET_ENV=stage
CMD ["./multi-stage"]
