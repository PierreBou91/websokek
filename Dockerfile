# Build Stage
FROM rust:latest AS build

WORKDIR /usr/src/

RUN apt-get update && apt-get install -y cmake libclang-dev

# Copy over your source code
COPY . .

# Compile the Rust application
RUN cargo build --release

# Runtime Stage
FROM debian:bullseye-slim

# Copy the compiled binary from the build stage
COPY --from=build /usr/src/target/release/websokek /usr/local/bin/

# Execute the binary
CMD ["websokek"]
