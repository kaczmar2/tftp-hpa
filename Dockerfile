FROM debian:bookworm-slim

LABEL maintainer="kaczmar2"
LABEL description="Minimal TFTP server based on Debian Bookworm Slim and tftpd-hpa"

RUN apt-get update && \
    apt-get install -y --no-install-recommends tftpd-hpa socat && \
    apt-get -y autoremove && \
    apt-get -y clean && \
    rm -rf /var/lib/apt/lists/*

EXPOSE 69/udp

# Set default TFTP arguments (can be overridden via environment variables)
ENV TFTP_ARGS="--foreground --secure --verbosity 4 --user tftp"

# Set working directory
WORKDIR /srv/tftp

# Create startup script with socat for syslog redirection
RUN echo '#!/bin/bash' > /start-tftp.sh && \
    echo 'echo "Starting tftpd..."' >> /start-tftp.sh && \
    echo 'socat -u UNIX-RECV:/dev/log STDOUT &' >> /start-tftp.sh && \
    echo 'sleep 1' >> /start-tftp.sh && \
    echo 'echo "Executing: /usr/sbin/in.tftpd ${TFTP_ARGS} /srv/tftp"' >> /start-tftp.sh && \
    echo 'exec /usr/sbin/in.tftpd ${TFTP_ARGS} /srv/tftp' >> /start-tftp.sh && \
    chmod +x /start-tftp.sh

CMD ["/start-tftp.sh"]