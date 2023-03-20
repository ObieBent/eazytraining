FROM bitnami/apache:latest

COPY ./src/ /var/www/html

USER 1001

CMD [ "httpd -D FOREGROUND" ]