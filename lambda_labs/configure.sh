#!/bin/bash

error_exit() {
    echo "Error: $1" >&2
    exit 1
}

if [ "$#" -lt 2 ]; then
    error_exit "Usage: $0 <remote-ip> <path-to-ssh-key>"
fi

REMOTE_IP="$1"
VM_SSH_KEY_PATH="$2"

if [ -f "$HOME/.ssh/id_ed25519" ]; then
    GITHUB_SSH_KEY="$HOME/.ssh/id_ed25519"
    echo "Found GitHub SSH key at $GITHUB_SSH_KEY"
elif [ -f "$HOME/.ssh/id_rsa" ]; then
    GITHUB_SSH_KEY="$HOME/.ssh/id_rsa"
    echo "Found GitHub SSH key at $GITHUB_SSH_KEY"
else
    error_exit "No GitHub SSH key found at ~/.ssh/id_ed25519 or ~/.ssh/id_rsa"
fi

[ ! -f "$VM_SSH_KEY_PATH" ] && error_exit "VM SSH key file not found at: $VM_SSH_KEY_PATH"

echo "Ensuring SSH agent is running and keys are loaded..."
eval "$(ssh-agent -s)"
ssh-add "$VM_SSH_KEY_PATH" || error_exit "Failed to add VM SSH key to agent"
ssh-add "$GITHUB_SSH_KEY" || error_exit "Failed to add GitHub SSH key to agent"

echo "Keys currently loaded in SSH agent:"
ssh-add -l

echo "Adding GitHub's host key to remote machine's known_hosts..."
ssh -i "$VM_SSH_KEY_PATH" ubuntu@$REMOTE_IP 'mkdir -p ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts'

SSH_CONFIG="$HOME/.ssh/config"
SSH_DIR="$HOME/.ssh"

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

if grep -q "^Host $REMOTE_IP$" "$SSH_CONFIG" 2>/dev/null; then
    sed -i.bak "/^Host $REMOTE_IP$/,/^$/ {
        s/[[:space:]]*HostName .*/    HostName $REMOTE_IP/
        s/[[:space:]]*ForwardAgent .*/    ForwardAgent yes/
    }" "$SSH_CONFIG"
    echo "Updated SSH config for $REMOTE_IP"
else
    echo -e "\nHost $REMOTE_IP\n    HostName $REMOTE_IP\n    User ubuntu\n    ForwardAgent yes" >>"$SSH_CONFIG"
    echo "Added new SSH configuration for $REMOTE_IP"
fi

chmod 600 "$SSH_CONFIG"

FILES_TO_COPY=(".env" ".bash_aliases" "setup.sh")

copy_file() {
    local filename="$1"
    echo "Copying $filename to remote machine..."
    if [ -f "$(dirname "$0")/$filename" ]; then
        scp -i "$VM_SSH_KEY_PATH" "$(dirname "$0")/$filename" "ubuntu@$REMOTE_IP:~/$filename" || error_exit "Failed to copy $filename file"
        echo "$filename file copied successfully"
    else
        echo "Warning: $filename file not found in script directory, skipping..."
    fi
}

for file in "${FILES_TO_COPY[@]}"; do
    copy_file "$file"
done

ssh -i "$VM_SSH_KEY_PATH" ubuntu@$REMOTE_IP "bash ~/setup.sh"