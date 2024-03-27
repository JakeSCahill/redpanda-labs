#!/bin/bash
set -e

# Function to check rpk installation and display its version
check_rpk_installed() {
    if command -v rpk &>/dev/null; then
        echo "rpk is already installed. Version information:"
        rpk version
        return 0
    else
        return 1
    fi
}

# Determine OS and architecture
OS="$(uname -s)"
ARCH="$(uname -m)"

# Check if rpk is already installed
if check_rpk_installed; then
    exit 0
fi

# Check if running on macOS and use Homebrew to install rpk
if [ "${OS}" == "Darwin" ]; then
    echo "Detected macOS. Attempting to install rpk using Homebrew..."

    # Check if Homebrew is installed
    if ! command -v brew &>/dev/null; then
        echo "Homebrew not found."
        exit 1
    fi

    # Install rpk
    brew install redpanda-data/tap/redpanda

    # Verify installation
    echo "rpk has been installed. Version information:"
    rpk version
    exit 0
fi

# For Linux systems
if [ "${OS}" == "Linux" ]; then
    FILENAME="rpk-linux-amd64.zip"
    URL_BASE="https://github.com/redpanda-data/redpanda/releases"

    # Download latest version of rpk
    echo "Downloading ${FILENAME}..."
    curl -LO "${URL_BASE}/latest/download/${FILENAME}"

    # Ensure the target directory exists
    mkdir -p $HOME/.local/bin

    # Add the target directory to PATH in the current session
    export PATH=$PATH:$HOME/.local/bin

    # Unzip the rpk binary to the target directory
    unzip -o "${FILENAME}" -d $HOME/.local/bin

    # Remove the downloaded archive
    rm "${FILENAME}"

    # Add the target directory to PATH
    echo "$HOME/.local/bin" >> $GITHUB_PATH

    # Verify installation
    echo "rpk has been installed. Version information:"
    rpk version
    exit 0
fi

echo "Unsupported operating system: ${OS}"
exit 1