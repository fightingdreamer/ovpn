FROM docker.io/library/alpine:3.18 as base

RUN apk add openvpn

COPY ./root/opt /opt
RUN chmod 0400 /opt/openvpn/pki/private/*.key

ENTRYPOINT [ "sh", "/opt/entrypoint.sh" ]
