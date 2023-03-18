FROM registry.redhat.io/rhscl/httpd:2.4-el7 

RUN sed -i 's/^Listen 80/Listen 8080/g' /etc/httpd/conf/httpd.conf 

ADD src/ /var/www/html/ 

USER 1000 

CMD httpd -DFOREGROUND
