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

echo "Verifying GitHub SSH access..."
if ! ssh -T git@github.com 2>&1 | grep -q "success"; then
    error_exit "GitHub SSH verification failed. Please check your GitHub SSH setup."
fi
echo "GitHub SSH verification successful!"

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

echo "Copying .env to remote machine..."
if [ -f "$(dirname "$0")/.env" ]; then
    scp -i "$VM_SSH_KEY_PATH" "$(dirname "$0")/.env" "ubuntu@$REMOTE_IP:~/.env" || error_exit "Failed to copy .env file"
    echo ".env file copied successfully"
else
    echo "Warning: .env file not found in script directory, skipping..."
fi

echo "Copying .bash_aliases to remote machine..."
if [ -f "$(dirname "$0")/.bash_aliases" ]; then
    scp -i "$VM_SSH_KEY_PATH" "$(dirname "$0")/.bash_aliases" "ubuntu@$REMOTE_IP:~/.bash_aliases" || error_exit "Failed to copy .bash_aliases file"
    echo ".bash_aliases file copied successfully"
else
    echo "Warning: .bash_aliases file not found in script directory, skipping..."
fi
