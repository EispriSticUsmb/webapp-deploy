FROM node:22-alpine AS build

ARG GITHUB_REPO=https://github.com/EispriSticUsmb/webapp-frontend.git
ARG GITHUB_BRANCH=main

WORKDIR /app

RUN apk add --no-cache git \
    && git clone --branch $GITHUB_BRANCH --depth 1 $GITHUB_REPO . \
    && npm install --include=dev

RUN npm run build

FROM node:22-alpine as runner

WORKDIR /app

ENV TZ=Europe/Paris
RUN apk add --no-cache tzdata \
 && cp /usr/share/zoneinfo/$TZ /etc/localtime \
  && echo $TZ > /etc/timezone \
  && apk del tzdata

COPY --from=build /app/dist/frontend-angular-eispri-stic /app/

EXPOSE 4000

CMD ["node", "server/server.mjs"]
