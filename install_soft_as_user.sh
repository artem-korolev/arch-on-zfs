#!/usr/bin/env bash

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
git config --global user.email "artkor@live.ru"
git config --global user.name "Artem Korolev"

# For my Rust projects
source ~/.cargo/env
cargo install trunk
rustup target add wasm32-unknown-unknown
