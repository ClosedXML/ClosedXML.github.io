#!/usr/bin/env bash

bundle install
bundle exec jekyll serve --force_polling --livereload --config _config.yml --host 0.0.0.0