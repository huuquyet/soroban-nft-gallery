FROM gitpod/workspace-full:2023-10-03-17-29-28

RUN mkdir -p ~/.local/bin

RUN curl -L https://github.com/stellar/soroban-tools/releases/download/v20.0.0-rc.4.1/soroban-cli-20.0.0-rc.4.1-x86_64-unknown-linux-gnu.tar.gz | tar xz -C ~/.local/bin soroban
RUN chmod +x ~/.local/bin/soroban
RUN echo "source <(soroban completion --shell bash)" >> ~/.bashrc

RUN curl -L https://github.com/mozilla/sccache/releases/download/v0.7.3/sccache-v0.7.3-x86_64-unknown-linux-musl.tar.gz | tar xz --strip-components 1 -C ~/.local/bin sccache-v0.7.3-x86_64-unknown-linux-musl/sccache
RUN chmod +x ~/.local/bin/sccache

RUN curl -L https://github.com/watchexec/cargo-watch/releases/download/v8.4.1/cargo-watch-v8.4.1-x86_64-unknown-linux-gnu.tar.xz | tar xJ --strip-components 1 -C ~/.local/bin cargo-watch-v8.4.1-x86_64-unknown-linux-gnu/cargo-watch

RUN curl -LO https://github.com/denoland/deno/releases/download/v1.38.3/deno-x86_64-unknown-linux-gnu.zip
RUN unzip deno-x86_64-unknown-linux-gnu.zip -d ~/.local/bin

ENV RUSTC_WRAPPER=sccache
ENV SCCACHE_CACHE_SIZE=5G
ENV SCCACHE_DIR=/workspace/.sccache

# In order to reliably install the most up-to-date version of Rust, we first
# uninstall the existing toolchain.
# https://github.com/gitpod-io/workspace-images/issues/933#issuecomment-1272616892
RUN rustup self uninstall -y
RUN rm -rf .rustup
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --default-toolchain none -y

RUN rustup install 1.74 --component rust-src
RUN rustup target add --toolchain 1.74 wasm32-unknown-unknown
RUN rustup default 1.74

RUN sudo apt-get update && sudo apt-get install -y binaryen

# Enable sparse registry support, which will cause cargo to download only what
# it needs from crates.io, rather than the entire registry.
ENV CARGO_REGISTRIES_CRATES_IO_PROTOCOL=sparse
