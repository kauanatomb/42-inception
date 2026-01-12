FROM debian:bullseye

# install programs
RUN apt-get update && apt-get install -y nginx openssl \
    apt-get install -y curl \
    && rm -rf /var/lib/apt/lists/*

# generate self-signed ssl certs
RUN mkdir -p /etc/nginx/ssl
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/nginx.key \
    -out /etc/nginx/ssl/nginx.crt \
    -subj "/C=FR/ST=IDF/L=Paris/O=42/CN=${DOMAIN_NAME}"

# copy nginx conf
COPY conf/default.conf /etc/nginx/sites-available/default

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]