FROM ubuntu:12.04

RUN apt-get update
RUN apt-get install -y curl python-pip
RUN pip install awscli
ADD ./s3-backup /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/s3-backup"]
