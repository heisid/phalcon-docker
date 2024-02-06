FROM php:7.2-apache

ENV PHALCON_VERSION=3.2.2
ENV PHALCON_DEV_TOOLS_VERSION=3.2.0

RUN echo "deb http://archive.debian.org/debian stretch main" > /etc/apt/sources.list
RUN apt-get update && apt-get install -y libpq-dev && docker-php-ext-install pdo pdo_pgsql

# Install PHP GD EXTENSION
RUN apt-get update && apt-get install -y --allow-downgrades \
        zlib1g=1:1.2.8.dfsg-5 \
        zlib1g-dev \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
#    && docker-php-ext-install -j$(nproc) iconv mcrypt \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd

# PHP Zip
RUN apt-get install -y \
        libzip-dev \
        zip \
        && docker-php-ext-install zip

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Compile Phalcon
RUN set -xe && \
        curl -LO https://github.com/phalcon/cphalcon/archive/v${PHALCON_VERSION}.tar.gz && \
        tar xzf v${PHALCON_VERSION}.tar.gz && cd cphalcon-${PHALCON_VERSION}/build && ./install && \
        docker-php-ext-enable phalcon && \
        cd ../.. && rm -rf v${PHALCON_VERSION}.tar.gz cphalcon-${PHALCON_VERSION} && \
        # Insall Phalcon Devtools, https://github.com/phalcon/phalcon-devtools/
        curl -LO https://github.com/phalcon/phalcon-devtools/archive/v${PHALCON_DEV_TOOLS_VERSION}.tar.gz && \
        tar xzf v${PHALCON_DEV_TOOLS_VERSION}.tar.gz && \
        mv phalcon-devtools-${PHALCON_DEV_TOOLS_VERSION} /usr/local/phalcon-devtools && \
        ln -s /usr/local/phalcon-devtools/phalcon.php /usr/local/bin/phalcon

# APCU
RUN pecl install apcu \
    && pecl install apcu_bc-1.0.3 \
    && docker-php-ext-enable apcu --ini-name 10-docker-php-ext-apcu.ini \
    && docker-php-ext-enable apc --ini-name 20-docker-php-ext-apc.ini

COPY 000-default.conf /etc/apache2/sites-available/000-default.conf

COPY . /var/www/html
WORKDIR /var/www/html

EXPOSE 80
EXPOSE 443

RUN a2enmod rewrite
RUN /etc/init.d/apache2 restart

CMD ["apache2-foreground"]
