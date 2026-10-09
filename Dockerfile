FROM php:8.3-apache
RUN a2enmod rewrite headers
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri 's!/var/www/html!/var/www/html/public!g' /etc/apache2/sites-available/*.conf /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf
COPY . /var/www/html/
COPY preview/assets/ /var/www/html/public/assets/
RUN chown -R www-data:www-data /var/www/html
EXPOSE 80
