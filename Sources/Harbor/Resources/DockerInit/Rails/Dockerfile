FROM ruby:|RUBY_VERSION|-alpine

# Install base dependencies
RUN apk add --no-cache imagemagick postgresql-client tzdata nodejs dcron gnupg file curl gcompat

# Use jemalloc to improve memory usage \
RUN apk add build-base \
    && wget -O - https://github.com/jemalloc/jemalloc/releases/download/5.3.0/jemalloc-5.3.0.tar.bz2 | tar -xj \
    && cd jemalloc-5.3.0 \
    && ./configure \
    && make \
    && make install \
    && apk del build-base \
    && cd .. \
    && rm -rf jemalloc-5.3.0
ENV LD_PRELOAD=/usr/local/lib/libjemalloc.so.2

# Start image
WORKDIR /app

# Install gems
ARG BUNDLE_WITHOUT=development:test:tools
COPY Gemfile Gemfile.lock /app/
RUN apk add --virtual .build-deps build-base postgresql-dev git tzdata \
    && gem install bundler \
    && bundle config set without ${BUNDLE_WITHOUT} \
    && bundle install --no-cache -j4 --retry 3 \
    # Remove unneeded files (cached *.gem, *.o, *.c)
    && rm -rf /usr/local/bundle/cache \
    && rm -rf /root/.bundle/cache \
    && find /usr/local/bundle/gems/ -name "*.c" -delete \
    && find /usr/local/bundle/gems/ -name "*.o" -delete \
    && apk del .build-deps

# NB: master.key must be present in ./config
COPY . /app

# Prepare build env
ENV RAILS_ENV production
ENV RAILS_SERVE_STATIC_FILES true

ARG RAILS_MASTER_KEY
ARG APP_HOST
ENV APP_HOST ${APP_HOST}

ARG APP_VERSION
ENV APP_VERSION ${APP_VERSION}

# Precompile assets
RUN sh -c "PRECOMPILING_ASSETS=1 bundle exec rake assets:precompile" \
    && rm -rf tmp/cache

# Startup
EXPOSE 3000
CMD ["./docker_startup.sh"]
