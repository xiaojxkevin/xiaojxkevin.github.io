FROM docker.1ms.run/library/ruby:3.2-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && apt-get install -y --no-install-recommends \
    build-essential \
    zlib1g-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN gem install bundler

RUN mkdir -p /srv/jekyll
WORKDIR /srv/jekyll

# Install dependencies first for better layer caching
COPY Gemfile /srv/jekyll/
RUN bundle install

EXPOSE 4000

CMD ["bundle", "exec", "jekyll", "serve", "--host", "0.0.0.0", "--watch", "--livereload"]
