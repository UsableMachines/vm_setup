# VM Setup Scripts

This repository contains scripts for setting up and configuring Lambda Labs instances for the purpose of running kindo-evals. The scripts automate the process of setting up SSH configurations, installing necessary tools, and configuring the development environment.

## Repository Structure

- `lambda_labs/` - Contains all scripts and configuration files for Lambda Labs VM setup
  - `configure.sh` - Main configuration script that handles SSH setup and file deployment
  - `setup.sh` - Installation script that runs on the remote VM
  - `.example.env` - Template for environment variables
  - `.env` - Active environment configuration file
  - `.bash_aliases` - Useful shell aliases for development

## Prerequisites

- SSH key for GitHub access (either `~/.ssh/id_ed25519` or `~/.ssh/id_rsa`)
- SSH key for VM access
- Active GitHub SSH configuration

## Usage

1. Copy `.example.env` to `.env` and fill in your API keys and configuration values:
   ```bash
   cp lambda_labs/.example.env lambda_labs/.env
   ```

2. Run the configuration script with your VM's IP address and SSH key path:
   ```bash
   ./lambda_labs/configure.sh <remote-ip> <path-to-ssh-key>
   ```

The script will:
- Verify and set up SSH agent with required keys
- Configure SSH settings for the remote VM
- Copy necessary files to the remote machine
- Execute the setup script on the remote VM

## Features

- Automated SSH configuration
- Environment variable management
- Installation of development tools
- Repository cloning and setup
- Convenient bash aliases for development

## Security Notes

- The `.env` file contains sensitive API keys and should never be committed to version control
- SSH keys and configurations are handled securely with appropriate permissions
- SSH agent forwarding is enabled for seamless GitHub access from the VM 