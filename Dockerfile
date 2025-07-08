# Use Debian Bookworm as base image
FROM debian:bookworm-slim

# Set metadata
LABEL maintainer="Christian Kaczmarek"
LABEL description="TFTP Server using tftp-hpa"
LABEL version="1.0"

# Install tftpd-hpa package and rsyslog for log redirection
RUN apt-get update && \
    apt-get install -y --no-install-recommends tftpd-hpa rsyslog && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Expose TFTP port (documentation - ignored with network_mode: host)
EXPOSE 69/udp

# Create and prepare TFTP directory
RUN mkdir -p /srv/tftp && \
    chown tftp:nogroup /srv/tftp && \
    chmod 755 /srv/tftp

# Create startup script for log redirection
RUN echo '#!/bin/bash' > /start-tftp.sh && \
    echo 'rsyslogd' >> /start-tftp.sh && \
    echo 'tail -f /var/log/syslog &' >> /start-tftp.sh && \
    echo 'exec /usr/sbin/in.tftpd --foreground --secure --verbosity 4 --user tftp /srv/tftp' >> /start-tftp.sh && \
    chmod +x /start-tftp.sh

# Set working directory
WORKDIR /srv/tftp

CMD ["/start-tftp.sh"]