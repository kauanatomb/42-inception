FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    php7.4 \
    php7.4-fpm \
    php7.4-mysql \
    mariadb-client \
    curl \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install WP-CLI
RUN curl -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x /usr/local/bin/wp

# WordPress directory
RUN mkdir -p /var/www/html \
    && chown -R www-data:www-data /var/www/html

COPY tools/script.sh /usr/local/bin/script.sh
RUN chmod +x /usr/local/bin/script.sh

WORKDIR /var/www/html

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/script.sh"]
