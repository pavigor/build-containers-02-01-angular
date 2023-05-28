FROM node:18.16-buster-slim as source

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get install -y chromium

WORKDIR /app
COPY . .

RUN npm ci

FROM source as linter
COPY --from=source /app /app

WORKDIR /app
RUN npm run lint

FROM source as test-runner
COPY --from=source /app /app

WORKDIR /app
ENV CHROMIUM_FLAGS="--no-sandbox --disable-gpu --headless --user-data-dir=~/data --remote-debugging-port=9222"
ENV CHROMIUM_BIN="/usr/bin/chromium"
RUN npm run test -- --browsers=ChromiumHeadless --watch=false

FROM source as builder

# This is ugly, but needs for lint stage execution
COPY --from=linter /app/package.json /app/package.json
# This is ugly, but needs for test stage execution
COPY --from=test-runner /app/package.json /app/package.json
COPY --from=source /app /app
WORKDIR /app

RUN npm run build-storybook

FROM nginx:1.12

COPY --from=builder /app/storybook-static /usr/share/nginx/html

# https://github.com/storybookjs/storybook/issues/20157
RUN sed -i 's/\(\s*\)\(.*\)\(\s*\)\(js;\)/\1\2js mjs;/g' /etc/nginx/mime.types

