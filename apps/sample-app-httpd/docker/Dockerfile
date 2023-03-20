FROM quay.io/centos7/httpd-24-centos7:latest

COPY ./src/ /var/www/html

USER 1001

CMD httpd -D FOREGROUND
