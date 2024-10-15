FROM alpine:latest

# Install apache and utilities
RUN apk add --no-cache apache2 apache2-utils apache2-proxy apache2-ssl curl

# Copy web app materials
COPY htdocs /var/www/localhost/htdocs

# Copy the proxy file
COPY backend-proxy.conf /etc/apache2/conf.d/backend-proxy.conf

# Copy the required wizexercise.txt file
COPY wizexercise.txt ./

# Set the working directory
WORKDIR /usr/src/app

# Copy the entrypoint script
COPY entrypoint.sh /usr/src/app/entrypoint.sh

# Ensure entrypoint script is executable
RUN chmod +x /usr/src/app/entrypoint.sh

# Expose necessary ports
EXPOSE 80 443

# Set the entrypoint to run the entrypoint script
ENTRYPOINT ["/usr/src/app/entrypoint.sh"]
