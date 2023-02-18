#!/bin/sh

# If database exists, migrate. Otherwise setup (create and seed)
bundle exec rake db:prepare && echo "Database is ready!"

# Update cron (when using Whenever gem)
# bundle exec whenever --set environment="${RAILS_ENV}" --update-crontab && touch ./log/cron.log

# Startup
mkdir -p ./tmp/pids
crond && bundle exec puma -C config/puma.rb
