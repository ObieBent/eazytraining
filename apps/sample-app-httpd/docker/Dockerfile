FROM bitnami/apache:latest

COPY ./src/ /var/www/html

USER 1001

RUN chown -R 1001 /etc/httpd