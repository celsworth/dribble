FROM ruby:2.7-alpine

RUN apk add --no-cache g++ gcc make musl-dev bash nodejs npm
RUN npm install elm

# wouldn't be necessary if npm install -g elm worked?
ENV PATH /node_modules/elm/bin:$PATH

WORKDIR /var/app

COPY Gemfile* ./
RUN bundle install -j4

COPY . .

ENTRYPOINT ["bundle", "exec"]
