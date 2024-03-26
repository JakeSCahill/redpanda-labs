#!/bin/bash

# Function to check if expect and jq are installed and install them if they're not
ensure_dependencies_installed() {
    local missing_deps=0

    if ! command -v expect &> /dev/null; then
        echo "Expect is not installed. Trying to install..."
        missing_deps=1

        # Detect OS
        case "$(uname -s)" in
            Linux)
                echo "Detected Linux."
                sudo apt-get update && sudo apt-get install expect -y || sudo yum install expect -y
                ;;
            Darwin)
                echo "Detected macOS."
                # Assumes Homebrew is installed. If not, it attempts to install Homebrew first.
                if ! command -v brew &> /dev/null; then
                    echo "Homebrew not found."
                    exit 1
                fi
                brew install expect
                ;;
            *)
                echo "Unsupported operating system. Please install expect manually."
                exit 1
                ;;
        esac
    fi

    if ! command -v jq &> /dev/null; then
        echo "jq is not installed. Trying to install..."
        missing_deps=1

        # Install jq based on OS
        case "$(uname -s)" in
            Linux)
                sudo apt-get install jq -y || sudo yum install jq -y
                ;;
            Darwin)
                brew install jq
                ;;
            *)
                echo "Unsupported operating system. Please install jq manually."
                exit 1
                ;;
        esac
    fi

    if [ "$missing_deps" -ne 0 ]; then
        echo "Installation of missing dependencies failed. Exiting."
        exit 1
    fi
}

# Ensure expect and jq are installed
ensure_dependencies_installed

# Check if user input is passed as an argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <user_input>"
    exit 1
fi

# The first command line argument is the user input
USER_INPUT="$1"
# Preprocess the JSON to ensure it's in a valid format for jq
PROCESSED_JSON=$(echo "$USER_INPUT" | sed "s/^'//" | sed "s/'$//" | jq -c '.' | base64)

echo "Prepared Message: $PROCESSED_JSON"

expect <<EOF
# Launch your command
spawn rpk topic produce src

# Send the prepared JSON message as input
send -- [exec echo "$PROCESSED_JSON" | base64 --decode]\r

# Wait a bit to ensure 'rpk' processes the message
# Adjust the sleep time based on how long 'rpk' typically takes
sleep 5

# Send SIGINT (CTRL+C)
send "\003"

expect eof
EOF

echo "Script completed."
