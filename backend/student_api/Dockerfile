FROM php:8.2-apache

# Enable Apache URL rewriting
RUN a2enmod rewrite

# Install MySQL PDO support
RUN docker-php-ext-install pdo pdo_mysql mysqli

# Copy PHP project files into Apache's web directory
COPY . /var/www/html/

# Set the working directory
WORKDIR /var/www/html/

# Expose the web server port
EXPOSE 80