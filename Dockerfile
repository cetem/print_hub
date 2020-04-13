FROM ruby:2.6-alpine3.11

# Patch to get global bins
ENV BUNDLE_BIN="$GEM_HOME/bin"
ENV PATH $BUNDLE_BIN:$PATH
ENV RAILS_ENV=production

RUN mkdir -p "$BUNDLE_BIN"
RUN chmod 777 "$BUNDLE_BIN"

RUN echo "gem: --no-rdoc --no-ri" >> ~/.gemrc && \
    apk --update add --virtual build-dependencies build-base postgresql-dev cups-dev && \
    apk --update add libpq bash libxml2 libxml2-dev libxml2-utils libxslt \
                        openssl zlib tzdata git openssh file imagemagick \
                        nodejs cups && \
    gem update --system && \
    gem install bundler

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock ./

RUN bundle config set deployment 'true' && \
    bundle install --jobs 8 && \
    apk del build-dependencies

ADD . ./

RUN cp config/app_config.example.yml config/app_config.yml && \
    cp config/secrets.example.yml config/secrets.yml && \
    bundle exec rails assets:precompile && \
    rm config/secrets.yml config/app_config.yml

EXPOSE 3000

CMD ["bundle", "exec", "rails", "s", "-b", "0.0.0.0"]
