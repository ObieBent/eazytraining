FROM centos7:latest 

RUN yum install -y httpd && sed -i 's/^Listen 80/Listen 8080/g' /etc/httpd/conf/httpd.conf

COPY ./src/ /var/www/html

USER 1001

CMD httpd -DFOREGROUND
