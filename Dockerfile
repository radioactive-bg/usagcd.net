FROM wordpress:php8.2-fpm-alpine

# Install necessary dependencies and Set up WordPress
RUN apk add --no-cache bash coreutils curl tar nginx mysql-client mariadb-connector-c \
    && cp -r /usr/src/wordpress/* /var/www/html/ \
    && cp /usr/src/wordpress/wp-config-docker.php /var/www/html/ \
    && echo "<?php require( dirname( __FILE__ ) . '/wp-config-docker.php' );" > /var/www/html/wp-config.php \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html \
    && mkdir -p /var/log/nginx \
    && touch /var/log/nginx/access.log /var/log/nginx/error.log

# Copy custom WordPress content,Nginx configuration,entrypoint script
COPY ./wp-content /var/www/html/wp-content
COPY ./usagcd-net-db-dump.sql /var/www/html/usagcd-net-db-dump.sql
COPY ./nginx.conf /etc/nginx/nginx.conf
COPY ./entrypoint.sh /entrypoint.sh

 #Set permissions
RUN chmod +x /entrypoint.sh \
    && chown -R www-data:www-data /var/www/html
    
# Expose HTTP port
EXPOSE 80

# Use our custom entrypoint that will handle DB import, then start services
ENTRYPOINT ["/entrypoint.sh"]
