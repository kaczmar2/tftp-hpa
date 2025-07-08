# Use Debian Bookworm as base image
FROM debian:bookworm-slim

# Set metadata
LABEL maintainer="Christian Kaczmarek"
LABEL description="TFTP Server using tftp-hpa"
LABEL version="1.0"

# Install tftpd-hpa package (server only)
RUN apt-get update && \
    apt-get install -y --no-install-recommends tftpd-hpa && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Expose TFTP port (documentation - ignored with network_mode: host)
EXPOSE 69/udp

# Set working directory
WORKDIR /srv/tftp

CMD ["/usr/sbin/in.tftpd", "--foreground", "--secure", "--verbosity", "4", "--user", "tftp", "/srv/tftp"]
# Start TFTP server using exact Debian init script syntax
# CMD ["/usr/sbin/in.tftpd", "--listen", "--user", "tftp", "--address", "0.0.0.0:69", "--secure", "--verbosity", "4", "/srv/tftp"]