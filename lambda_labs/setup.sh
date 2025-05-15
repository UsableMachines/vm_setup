#!/bin/bash

error_exit() {
    echo "Error: $1" >&2
    exit 1
}

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
    error_exit "Usage: $0 <remote-ip> <path-to-ssh-key> [path-to-env-file]"
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

echo "Connecting to remote VM..."
ssh -A -i "$VM_SSH_KEY_PATH" "ubuntu@$REMOTE_IP"
