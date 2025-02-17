FROM rust:1.84-alpine3.21 AS chef
RUN apk add --no-cache g++ pkgconf make cmake musl-dev protoc protobuf
RUN cargo install cargo-chef
WORKDIR /app

FROM chef AS planner
COPY ./example .
RUN cargo chef prepare --recipe-path recipe.json

FROM chef AS builder
ARG app_name
COPY --from=planner /app/recipe.json recipe.json
RUN cargo chef cook --release --recipe-path recipe.json
COPY ./proto /proto
COPY ./example/Cargo.toml ./Cargo.toml
COPY ./example/Cargo.lock ./Cargo.lock
COPY ./example/build.rs ./build.rs
COPY ./example/src ./src
RUN cargo build --locked --release --bin ${app_name}

FROM rust:1.84-alpine3.21 
ARG app_name
ENV APP_NAME ${app_name}
COPY --from=builder /app/target /app/target
CMD /app/target/release/${APP_NAME}
