FROM docker.io/library/composer:latest AS composer
FROM php:8.3-apache

# Install packages
RUN apt-get update && apt-get install -y \
    git \
    zip \
    curl \
    sudo \
    unzip \
    libicu-dev \
    libbz2-dev \
    libpng-dev \
    libjpeg-dev \
    libmcrypt-dev \
    libreadline-dev \
    libfreetype6-dev \
    g++ 

# Common PHP Extensions
RUN docker-php-ext-install \
    bz2 \
    intl \
    iconv \
    bcmath \
    opcache \
    calendar \
    pdo_mysql

# Install PHP Redis extension
RUN pecl install redis && docker-php-ext-enable redis

# Apache configuration
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN a2enmod rewrite

# Ensure PHP logs are captured by the container
ENV LOG_CHANNEL=stderr

# Set the working directory for the application
WORKDIR /var/www/html

# Copy the entire application code to the working directory
COPY . .

# Copy composer from official composer image
COPY --from=composer /usr/bin/composer /usr/bin/composer

# Run composer install separately to cache dependencies
RUN composer install --no-dev --prefer-dist --optimize-autoloader

# Change ownership
RUN chown -R www-data:www-data /var/www/html

# Expose port
EXPOSE 80
