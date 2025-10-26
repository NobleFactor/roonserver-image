# Install-RoonServer Documentation

Copyright (c) 2024 Noble Factor  
MIT License - See LICENSE.md for full license text

---

This directory contains the `Install-RoonServer` script along with its documentation and shell completions.

## Files

- **Install-RoonServer** - Main installation script
- **Install-RoonServer.1** - Man page documentation
- **Install-RoonServer.bash-completion** - Bash shell completion
- **_Install-RoonServer** - Zsh shell completion

## Installation

### Installing the Script

The script can be run directly from this directory:

```bash
sudo ./Install-RoonServer
```

Or you can install it to your PATH:

```bash
sudo cp Install-RoonServer /usr/local/bin/
sudo chmod 755 /usr/local/bin/Install-RoonServer
```

### Installing the Man Page

To install the man page so it's accessible via `man Install-RoonServer`:

```bash
sudo mkdir -p /usr/local/share/man/man1
sudo cp Install-RoonServer.1 /usr/local/share/man/man1/
sudo chmod 644 /usr/local/share/man/man1/Install-RoonServer.1
```

Then update the man page database:

```bash
sudo /usr/libexec/makewhatis /usr/local/share/man
```

### Installing Bash Completion

For bash completion support:

```bash
# For Homebrew bash-completion (recommended)
sudo cp Install-RoonServer.bash-completion /usr/local/etc/bash_completion.d/Install-RoonServer

# Or for system-wide installation
sudo cp Install-RoonServer.bash-completion /etc/bash_completion.d/Install-RoonServer
```

Then reload your bash configuration or start a new shell session.

### Installing Zsh Completion

For zsh completion support:

```bash
# Create the site-functions directory if it doesn't exist
sudo mkdir -p /usr/local/share/zsh/site-functions

# Copy the completion file
sudo cp _Install-RoonServer /usr/local/share/zsh/site-functions/

# Ensure the directory is in your fpath (add to ~/.zshrc if needed)
echo 'fpath=(/usr/local/share/zsh/site-functions $fpath)' >> ~/.zshrc

# Rebuild completion cache
rm -f ~/.zcompdump
compinit
```

Or for user-specific installation:

```bash
# Create user completion directory
mkdir -p ~/.zsh/completion

# Copy the completion file
cp _Install-RoonServer ~/.zsh/completion/

# Add to ~/.zshrc
echo 'fpath=(~/.zsh/completion $fpath)' >> ~/.zshrc
echo 'autoload -Uz compinit && compinit' >> ~/.zshrc

# Rebuild completion cache
rm -f ~/.zcompdump
compinit
```

## Usage

### Basic Usage

Install with default settings:

```bash
sudo Install-RoonServer
```

### Advanced Usage

Specify custom data directory:

```bash
sudo Install-RoonServer --roon-dataprefix /Volumes/Storage/Roon
```

Specify custom user and data directory:

```bash
sudo Install-RoonServer --roon-user roonuser --roon-dataprefix /opt/roon
```

### Getting Help

View the help message:

```bash
Install-RoonServer --help
```

View the man page:

```bash
man Install-RoonServer
```

## Post-Installation

After running the script, you **must** grant local area network access to Roon Server:

1. Go to **System Settings** > **Privacy & Security** > **Local Network**
2. Find **Roon Server** in the list
3. Toggle the switch to **allow** network access

## Verification

Check if RoonServer is running:

```bash
sudo launchctl list | grep roonserver
```

View the daemon status:

```bash
sudo launchctl print system/com.noblefactor.roon.RoonServer
```

Check logs:

```bash
tail -f /var/log/roon/RoonServer.out
tail -f /var/log/roon/RoonServer.err
```

## Troubleshooting

If you encounter issues:

1. Check that you ran the script with `sudo`
2. Verify log files in `/var/log/roon/`
3. Ensure local network access is granted in System Settings
4. Check that the data directory is accessible by the specified user
5. Review the [troubleshooting guide](https://docs.google.com/document/d/1qWmUs5pWz4iu0M9RYO6FEU8a7QpUl7RNydbeZ7FgmCk/edit?usp=sharing)

## Uninstallation

To remove RoonServer:

```bash
# Stop and remove the LaunchDaemon
sudo launchctl bootout system/com.noblefactor.roon.RoonServer
sudo rm /Library/LaunchDaemons/com.noblefactor.roon.RoonServer.plist

# Remove the application
sudo rm -rf /Applications/Roon.app

# Optionally remove logs
sudo rm -rf /var/log/roon
```

## Support

Report issues at: <https://github.com/NobleFactor/roonserver-image/issues>
