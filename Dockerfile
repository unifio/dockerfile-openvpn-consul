# Original credit: https://github.com/jpetazzo/dockvpn

# Smallest base image
FROM alpine:3.4

MAINTAINER Kyle Manna <kyle@kylemanna.com>

# Needed for hashicorp tool install 
ENV ENVCONSUL_VERSION=0.6.1
ENV CONSULTEMPLATE_VERSION=0.16.0

RUN echo "http://dl-4.alpinelinux.org/alpine/edge/community/" >> /etc/apk/repositories && \
    echo "http://dl-4.alpinelinux.org/alpine/edge/testing/" >> /etc/apk/repositories && \
    apk add --update openvpn curl unzip iptables bash easy-rsa \
    openvpn-auth-ldap openvpn-auth-pam google-authenticator pamtester groff \
    less python gnupg py-pip && \
    ln -s /usr/share/easy-rsa/easyrsa /usr/local/bin && \
    pip install awscli && \
    apk --purge -v del py-pip && \
    mkdir -p /tmp/build && \
    cd /tmp/build && \
    curl -s --output envconsul_${ENVCONSUL_VERSION}_linux_amd64.zip https://releases.hashicorp.com/envconsul/${ENVCONSUL_VERSION}/envconsul_${ENVCONSUL_VERSION}_linux_amd64.zip && \
    curl -s --output envconsul_${ENVCONSUL_VERSION}_SHA256SUMS https://releases.hashicorp.com/envconsul/${ENVCONSUL_VERSION}/envconsul_${ENVCONSUL_VERSION}_SHA256SUMS && \
    curl -s --output envconsul_${ENVCONSUL_VERSION}_SHA256SUMS.sig https://releases.hashicorp.com/envconsul/${ENVCONSUL_VERSION}/envconsul_${ENVCONSUL_VERSION}_SHA256SUMS.sig && \
    curl -s --output consul-template_${CONSULTEMPLATE_VERSION}_linux_amd64.zip https://releases.hashicorp.com/consul-template/${CONSULTEMPLATE_VERSION}/consul-template_${CONSULTEMPLATE_VERSION}_linux_amd64.zip && \
    curl -s --output consul-template_${CONSULTEMPLATE_VERSION}_SHA256SUMS https://releases.hashicorp.com/consul-template/${CONSULTEMPLATE_VERSION}/consul-template_${CONSULTEMPLATE_VERSION}_SHA256SUMS && \
    curl -s --output consul-template_${CONSULTEMPLATE_VERSION}_SHA256SUMS.sig https://releases.hashicorp.com/consul-template/${CONSULTEMPLATE_VERSION}/consul-template_${CONSULTEMPLATE_VERSION}_SHA256SUMS.sig && \
    gpg --keyserver keys.gnupg.net --recv-keys 91A6E7F85D05C65630BEF18951852D87348FFC4C && \
    gpg --batch --verify envconsul_${ENVCONSUL_VERSION}_SHA256SUMS.sig envconsul_${ENVCONSUL_VERSION}_SHA256SUMS && \
    gpg --batch --verify consul-template_${CONSULTEMPLATE_VERSION}_SHA256SUMS.sig consul-template_${CONSULTEMPLATE_VERSION}_SHA256SUMS && \
    grep envconsul_${ENVCONSUL_VERSION}_linux_amd64.zip envconsul_${ENVCONSUL_VERSION}_SHA256SUMS | sha256sum -c && \
    grep consul-template_${CONSULTEMPLATE_VERSION}_linux_amd64.zip consul-template_${CONSULTEMPLATE_VERSION}_SHA256SUMS | sha256sum -c && \
    unzip -d /usr/local/bin envconsul_${ENVCONSUL_VERSION}_linux_amd64.zip && \
    unzip -d /usr/local/bin consul-template_${CONSULTEMPLATE_VERSION}_linux_amd64.zip && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/* /var/cache/distfiles/*

# Needed by scripts
ENV OPENVPN /etc/openvpn
ENV EASYRSA /usr/share/easy-rsa
ENV EASYRSA_PKI $OPENVPN/pki
ENV EASYRSA_VARS_FILE $OPENVPN/vars

VOLUME ["/etc/openvpn"]

# Internally uses port 1194/udp, remap using `docker run -p 443:1194/tcp`
EXPOSE 1194/udp

CMD ["ovpn_run"]

ADD ./bin /usr/local/bin
RUN chmod a+x /usr/local/bin/*

# Add support for OTP authentication using a PAM module
ADD ./otp/openvpn /etc/pam.d/
