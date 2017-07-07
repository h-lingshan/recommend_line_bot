FROM ruby:2.1
ENV LANG C.UTF-8
ENV APP_ROOT /workspace
WORKDIR $APP_ROOT
RUN apt-get update && \
    apt-get install -y nodejs \
                       mysql-client \
                       redis-tools \
                       imagemagick \
                       libcurl3 \
                       --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*
COPY Gemfile $APP_ROOT
COPY Gemfile.lock $APP_ROOT
COPY . $APP_ROOT
RUN \
  gem install bundler && \
  echo 'gem: --no-document' >> ~/.gemrc && \
  cp ~/.gemrc /etc/gemrc && \
  chmod uog+r /etc/gemrc && \
  bundle config --global jobs 4 && \
  bundle install && \
  rm -rf ~/.gem