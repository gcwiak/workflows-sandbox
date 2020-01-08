FROM debian:latest

LABEL \
  "name"="GitHub Auto Pull Request Action" 

RUN apt update && apt install -y git
RUN apt install -y hub

ADD *.sh /

ENTRYPOINT ["/entrypoint.sh"]
