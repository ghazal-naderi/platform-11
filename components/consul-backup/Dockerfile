FROM alpine:3.11.6
LABEL maintainer="ehsan.ashouri@11fs.com"

ENV CONSUL_VERSION="1.8.1"

############DEV SETTINGS
# ENV CONSUL_HTTP_SSL_VERIFY="false"
# ENV CONSUL_HTTP_SSL="true"
# ENV FORCE_PATH_STYLE="true"
# ENV BACKUP_BUCKET="consul_prod_backup"
# ENV ENDPOINT_URL="https://fr9ckauowgwh.compat.objectstorage.me-jeddah-1.oraclecloud.com"
# ENV HTTP_ADDR="https://docker.for.mac.localhost:8500"
# ENV CONSUL_HTTP_TOKEN="PASSWORD"
# ENV CONSUL_BUCKET_ACCESS="PASSWORD"
# ENV CONSUL_BUCKET_SECRET="PASSWORD"
############

ADD https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip /tmp/consul.zip
ADD https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip /tmp/aws.zip

RUN apk add bash groff

RUN apk add --no-cache python py-pip
RUN pip install awscli

RUN unzip -q -d /tmp/ /tmp/consul.zip && mv /tmp/consul /usr/local/bin/consul && chmod +x /usr/local/bin/consul
RUN aws configure set default.region me-jeddah-1; aws configure set aws_access_key_id "$CONSUL_BUCKET_ACCESS" ; aws configure set aws_secret_access_key "$CONSUL_BUCKET_SECRET"

COPY consul-snapshot.sh ./
WORKDIR /workspace
VOLUME ["/workspace"]

# ENTRYPOINT ["sleep"]
# CMD ["100000"]
ENTRYPOINT ["/bin/ash","./consul-snapshot.sh"]