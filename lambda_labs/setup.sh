#!/bin/bash

source ~/.bashrc

if ! command -v uv &>/dev/null; then
    echo "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
else
    echo "uv is already installed, moving on..."
fi

if ! command -v yq &>/dev/null; then
    echo "Installing yq..."
    sudo snap install yq
else
    echo "yq is already installed, moving on..."
fi

if [ ! -d "kindo-evals" ]; then
    echo "Cloning kindo-evals repository..."
    git clone ssh://git@github.com/UsableMachines/kindo-evals.git
else
    echo "kindo-evals repository already exists, skipping clone..."
fi

echo "Running setup script from kindo-evals repository..."
~/kindo-evals/scripts/setup.sh

