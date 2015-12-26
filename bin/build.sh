#!/usr/bin/env bash

set -e

npm install -g topojson
npm install
bower install
npm run build
npm test
