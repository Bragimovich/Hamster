FROM ruby:2.7.1-alpine as builder

RUN apk add --update \
    build-base \
    curl \
    libressl-dev \
    libxml2-dev \
    libxslt-dev \
    mariadb-dev \
    openssl \
    openssl-dev \
    && rm -rf /var/cache/apk/*

COPY Gemfile ./

RUN echo 'gem: --no-document' > $HOME/.gemrc && \
    bundle install
RUN curl -L 'https://github.com/pdf2htmlEX/pdf2htmlEX/releases/download/v0.18.8.rc1/pdf2htmlEX-0.18.8.rc1-master-20200630-alpine-3.12.0-x86_64.tar.gz' > /pdf2htmlEX.tar.gz && \
    curl -L 'https://github.com/pdf2htmlEX/pdf2htmlEX/releases/download/v0.18.8.rc1/buildInfo-3.12.sh' > /buildInfo.sh && \
    tar -C / -xvf /pdf2htmlEX.tar.gz && \
    /bin/sh /buildInfo.sh


FROM ruby:2.7.1-alpine

RUN apk add --update \
    imagemagick \
    mariadb-dev \
    less \
    poppler-utils \
    tesseract-ocr \
    wkhtmltopdf \
    chromium \
    curl \
    tzdata \
    && rm -rf /var/cache/apk/*

COPY --from=builder /usr/local/bundle/ /usr/local/bundle/
COPY --from=builder /usr/local/bin/pdf2htmlEX /usr/local/bin/pdf2htmlEX
COPY --from=builder /usr/local/share/pdf2htmlEX/ /usr/local/share/pdf2htmlEX/

RUN addgroup -g 1000 hamster && \
    adduser -D -u 1000 -G hamster hamster

USER hamster
RUN mkdir -p /home/hamster/Hamster /home/hamster/HarvestStorehouse /home/hamster/ini/Hamster && \
    touch /home/hamster/HarvestStorehouse/.history
ENV HISTFILE=/home/hamster/HarvestStorehouse/.history
ENV TZ=America/Chicago
WORKDIR /home/hamster/Hamster

CMD /bin/sh
