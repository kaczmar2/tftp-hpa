# TFTP Server Docker Image

A minimal, secure TFTP server based on Debian Bookworm and `tftpd-hpa`.

## Features

- **Minimal footprint** - Based on `debian:bookworm-slim`
- **Security focused** - Runs with `--secure` chroot protection
- **Production ready** - Follows Debian best practices
- **Verbose logging** - Configurable logging levels
- **Host networking** - Avoids TFTP port mapping issues

## Quick Start

### Using Docker Compose (Recommended)

```bash
# Clone or create the project directory
mkdir tftp-server && cd tftp-server

# Create docker-compose.yml and Dockerfile
# Build and start
docker-compose up -d

# Check status
docker-compose ps
docker logs tftp-server
```

### Using Docker Run

```bash
# Build the image
docker build -t kaczmar2/tftp-hpa .

# Run with host networking
docker run -d \
  --name tftp-server \
  --network host \
  --restart unless-stopped \
  -v /srv/tftp:/srv/tftp \
  kaczmar2/tftp-hpa
```

## Configuration

### Docker Compose Setup

The `docker-compose.yml` file:

```yaml
services:
  tftp:
    build: .
    container_name: tftp-server
    image: kaczmar2/tftp-hpa
    restart: unless-stopped
    network_mode: host
    volumes:
      - /srv/docker/tftp:/srv/tftp
```

**Key configuration choices:**

- **`build: .`** - Builds from local Dockerfile during development
- **`image: kaczmar2/tftp-hpa`** - Tags the built image for Docker Hub
- **`network_mode: host`** - Required for TFTP (avoids ephemeral port issues)
- **Volume mount** - Maps host directory to container's `/srv/tftp`

### Dockerfile Structure

The Dockerfile follows these principles:

```dockerfile
# Minimal base image
FROM debian:bookworm-slim

# Package installation only
RUN apt-get update && \
    apt-get install -y --no-install-recommends tftpd-hpa && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Working directory
WORKDIR /srv/tftp

# Daemon command
CMD ["/usr/sbin/in.tftpd", "--listen", "--user", "tftp", "--address", "0.0.0.0:69", "--secure", "--verbosity", "4", "/srv/tftp"]
```

**Design decisions:**

- **`debian:bookworm-slim`** - Minimal base (~27MB) with full package compatibility
- **`--no-install-recommends`** - Installs only essential dependencies
- **`apt-get clean`** - Removes package cache to reduce image size
- **`WORKDIR /srv/tftp`** - Sets working directory for debugging convenience

### TFTP Daemon Configuration

The CMD uses these flags:

- **`--listen`** - Foreground mode for Docker containers
- **`--user tftp`** - Drops privileges after binding to port 69
- **`--address 0.0.0.0:69`** - Listens on all interfaces, port 69
- **`--secure`** - Enables chroot jail for security
- **`--verbosity 4`** - Verbose logging for debugging
- **`/srv/tftp`** - TFTP root directory

## Directory Structure

```
/srv/docker/tftp/          # Host directory (mapped to container)
├── file1.txt             # Files to serve via TFTP
├── file2.bin             # Any files you want accessible
└── subdirectory/         # Subdirectories are supported
    └── nested-file.txt
```

## Usage

### Testing TFTP Access

```bash
# Install TFTP client
sudo apt install tftp-hpa

# Test file download
tftp localhost
tftp> get file1.txt
tftp> quit

# Or one-liner
echo "get file1.txt" | tftp localhost
```

### Viewing Logs

```bash
# Real-time logs
docker logs -f tftp-server

# Check for TFTP requests (RRQ = Read Request)
docker logs tftp-server | grep RRQ
```

### File Management

```bash
# Add files to serve
cp myfile.txt /srv/docker/tftp/

# Check what files are available
ls -la /srv/docker/tftp/

# Set proper permissions (readable by all)
chmod 644 /srv/docker/tftp/*
```

## Network Requirements

### Host Networking

This container **requires** `network_mode: host` because:

- **TFTP uses dynamic ports** - Data transfers use random ephemeral ports
- **Port mapping doesn't work** - Docker can't map unknown future ports
- **Host networking is standard** - Most TFTP Docker images use this approach

### Firewall

Ensure UDP port 69 is accessible:

```bash
# UFW example
sudo ufw allow 69/udp

# iptables example  
sudo iptables -A INPUT -p udp --dport 69 -j ACCEPT
```

## Security

### Built-in Security Features

- **Chroot jail** - `--secure` restricts file access to `/srv/tftp` only
- **Privilege dropping** - Daemon drops from root to `tftp` user after binding to port 69
- **Read-only by default** - Only allows file downloads, not uploads
- **Container isolation** - Process runs in isolated Docker environment

### File Upload Support (Optional)

By default, the server only allows downloads. To enable uploads, modify the CMD:

```dockerfile
CMD ["/usr/sbin/in.tftpd", "--listen", "--user", "tftp", "--address", "0.0.0.0:69", "--secure", "--create", "/srv/tftp"]
```

**Warning**: `--create` reduces security by allowing clients to create new files.

## Troubleshooting

### Container Issues

**Container keeps restarting:**
```bash
# Check logs for errors
docker logs tftp-server

# Most common: port 69 already in use
sudo netstat -ulnp | grep :69
```

**Build failures:**
```bash
# Clear Docker cache and rebuild
docker-compose build --no-cache
```

### TFTP Issues

**Connection timeouts:**
```bash
# Verify container is running
docker ps

# Check if daemon is listening on port 69
docker exec tftp-server cat /proc/net/udp | grep :0045

# Test locally first
echo "get test.txt" | tftp localhost
```

**File not found errors:**
```bash
# Check files exist and have correct permissions
ls -la /srv/docker/tftp/

# Files should be readable (644 permissions)
chmod 644 /srv/docker/tftp/*
```

### Permission Issues

```bash
# Check file ownership
ls -la /srv/docker/tftp/

# Fix permissions if needed
chmod 755 /srv/docker/tftp/
chmod 644 /srv/docker/tftp/*
```

## Building and Customization

### Build Commands

```bash
# Build image
docker build -t kaczmar2/tftp-hpa .

# Build without cache
docker build --no-cache -t kaczmar2/tftp-hpa .

# Build with custom tag
docker build -t kaczmar2/tftp-hpa:1.0 .
```

### Customizing the Daemon

Modify the `CMD` in the Dockerfile to change behavior:

```dockerfile
# Example: Reduce verbosity
CMD ["/usr/sbin/in.tftpd", "--listen", "--user", "tftp", "--address", "0.0.0.0:69", "--secure", "--verbosity", "1", "/srv/tftp"]

# Example: IPv4 only
CMD ["/usr/sbin/in.tftpd", "--listen", "-4", "--user", "tftp", "--address", "0.0.0.0:69", "--secure", "/srv/tftp"]

# Example: Allow file uploads
CMD ["/usr/sbin/in.tftpd", "--listen", "--user", "tftp", "--address", "0.0.0.0:69", "--secure", "--create", "/srv/tftp"]
```

## Performance

- **Memory usage**: ~5-10MB per container
- **CPU usage**: Minimal (event-driven)
- **Image size**: ~80MB (Debian slim + tftpd-hpa)
- **Startup time**: <1 second

## License

This project follows the same license terms as the underlying `tftpd-hpa` package.