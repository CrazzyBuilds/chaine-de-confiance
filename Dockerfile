# Image de base épinglée par son digest : « alpine:3.23 » est un tag, qui peut
# pointer demain vers un autre contenu. Le digest désigne un contenu exact ;
# Dependabot propose de le mettre à jour quand Alpine publie des correctifs.

# stage compilation
FROM alpine:3.23@sha256:469c9ea410b9215eaee7976ba6c0639039b444be8e5d638f7abbada189971eb2 AS builder
WORKDIR /app

RUN apk add --no-cache nodejs npm

RUN addgroup -S node && adduser -S node -G node && chown node:node /app

USER node

COPY ./package*.json ./

RUN npm ci

COPY ./ ./

RUN npm run build

RUN npm ci --omit=dev

FROM alpine:3.23@sha256:469c9ea410b9215eaee7976ba6c0639039b444be8e5d638f7abbada189971eb2 AS runner
WORKDIR /app
RUN apk add --no-cache nodejs
RUN addgroup -S node && adduser -S node -G node && chown node:node /app
USER node
COPY --from=builder /app/package.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist

# D'où vient l'image : GHCR s'en sert pour la rattacher au repo.
LABEL org.opencontainers.image.source="https://github.com/CrazzyBuilds/chaine-de-confiance"

CMD [ "node", "dist/index.js" ]

