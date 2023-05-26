FROM node:18.16-buster-slim as builder

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get install -y chromium

WORKDIR /app
COPY . .

ENV CHROMIUM_FLAGS="--no-sandbox --disable-gpu --headless --user-data-dir=~/data --remote-debugging-port=9222"
ENV CHROMIUM_BIN="/usr/bin/chromium"

RUN npm install
RUN npm run lint & npm run test -- --browsers=ChromiumHeadless --watch=false
RUN npm run build-storybook

FROM nginx:1.12

COPY --from=builder /app/storybook-static /usr/share/nginx/html

# https://github.com/storybookjs/storybook/issues/20157
RUN sed -i 's/\(\s*\)\(.*\)\(\s*\)\(js;\)/\1\2js mjs;/g' /etc/nginx/mime.types

