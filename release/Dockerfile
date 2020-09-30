FROM alpine:latest AS elm-builder
RUN apk add --no-cache nodejs-npm
RUN npm install -g elm --unsafe-perm=true --allow-root
COPY frontend ./
RUN elm make src/Main.elm --output /dribble.js


FROM ruby:2.7-alpine AS ruby-builder
RUN apk add --no-cache build-base
COPY Gemfile* ./
RUN bundle config set without development
RUN bundle install -j4


FROM ruby:2.7-alpine
RUN adduser -D app
USER app
WORKDIR /home/app
COPY . .
COPY --from=elm-builder /dribble.js public/dribble.js
COPY --from=ruby-builder Gemfile.lock .
COPY --from=ruby-builder /usr/local/bundle /usr/local/bundle
EXPOSE 3000

ENTRYPOINT ["bundle", "exec"]
CMD ["thin", "start"]
