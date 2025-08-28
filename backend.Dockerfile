FROM node:22-alpine as base
FROM base AS installer

#RUN apk add --no-cache libc6-compat

WORKDIR /app

ARG GITHUB_REPO=https://github.com/EispriSticUsmb/webapp-backend.git
ARG GITHUB_BRANCH=main

RUN apk add --no-cache git \
    && git clone --branch $GITHUB_BRANCH --depth 1 $GITHUB_REPO . \
    && npm install --include=dev

RUN npx prisma generate

RUN npm run build

FROM base as prunner
WORKDIR /app

COPY --from=installer /app/node_modules ./node_modules
COPY --from=installer /app/package*.json ./

RUN npm prune --omit=dev

FROM base AS runner
WORKDIR /app

ENV TZ=Europe/Paris

RUN apk add --no-cache tzdata \
    && cp /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone \
    && apk del tzdata

COPY --from=prunner /app/package.json ./package.json
COPY --from=installer /app/dist ./dist
COPY --from=prunner /app/node_modules ./node_modules
COPY --from=installer /app/start.sh ./start.sh
COPY --from=installer /app/prisma ./prisma
RUN chmod +x start.sh

CMD ["./start.sh"]