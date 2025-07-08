FROM ruby:3.3-alpine

RUN apk add --no-cache \
  build-base \
  openssl-dev \
  libffi-dev \
  yaml-dev \
  zlib-dev \
  git

WORKDIR /app

COPY . .

RUN bundle install
