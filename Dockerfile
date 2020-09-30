FROM ruby:2.7-alpine

RUN apk add --no-cache g++ gcc make musl-dev bash nodejs-npm
RUN npm install -g elm --unsafe-perm=true --allow-root

WORKDIR /var/app

COPY Gemfile* ./
RUN bundle install -j4

ENTRYPOINT ["bundle", "exec"]
