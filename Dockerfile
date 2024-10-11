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

# Copy composer from official composer image
COPY --from=composer /usr/bin/composer /usr/bin/composer

# Copy composer.json and composer.lock first to cache dependencies layer
COPY composer.json composer.lock /var/www/html/

# Run composer install separately to cache dependencies
WORKDIR /var/www/html
RUN composer install --no-dev --prefer-dist --optimize-autoloader

# Copy source code (this is after dependencies installation to avoid invalidating cache)
COPY . /var/www/html

# Change ownership
RUN chown -R www-data:www-data /var/www/html

# Expose port
EXPOSE 80
