#!/usr/bin/env bash

set -e

yum install ruby
gem update --system
gem install compass
npm install -g topojson
npm install
npm run build
