# Use Debian Bookworm as base image
FROM debian:bookworm-slim

# Set metadata
LABEL maintainer="Christian Kaczmarek"
LABEL description="TFTP Server using tftp-hpa"
LABEL version="1.0"

# Install tftpd-hpa package and socat for simple syslog redirection
RUN apt-get update && \
    apt-get install -y --no-install-recommends tftpd-hpa socat && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Expose TFTP port (documentation - ignored with network_mode: host)
EXPOSE 69/udp

# Create and prepare TFTP directory
RUN mkdir -p /srv/tftp && \
    chown tftp:nogroup /srv/tftp && \
    chmod 755 /srv/tftp


# Set working directory
WORKDIR /srv/tftp

# Create startup script with socat for syslog redirection
RUN echo '#!/bin/bash' > /start-tftp.sh && \
    echo 'echo "Starting TFTP server with syslog redirection..."' >> /start-tftp.sh && \
    echo 'socat -u UNIX-RECV:/dev/log STDOUT &' >> /start-tftp.sh && \
    echo 'sleep 1' >> /start-tftp.sh && \
    echo 'exec /usr/sbin/in.tftpd --foreground --secure --verbosity 4 --user tftp /srv/tftp' >> /start-tftp.sh && \
    chmod +x /start-tftp.sh

CMD ["/start-tftp.sh"]