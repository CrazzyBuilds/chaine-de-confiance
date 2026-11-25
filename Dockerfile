# stage compilation
FROM alpine:3.20 AS builder
WORKDIR /app

RUN apk add --no-cache nodejs npm

RUN addgroup -S node && adduser -S node -G node && chown node:node /app

USER node

COPY ./package*.json ./

RUN npm ci

COPY ./ ./

RUN npm run build

RUN npm ci --omit=dev

FROM alpine:3.20 AS runner
WORKDIR /app
RUN apk add --no-cache nodejs
RUN addgroup -S node && adduser -S node -G node && chown node:node /app
USER node
COPY --from=builder /app/package.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist

CMD [ "node", "dist/index.js" ]

