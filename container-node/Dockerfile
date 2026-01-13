# Build
FROM node:20-alpine AS builder

WORKDIR /app

COPY package.json .

RUN npm install && npm cache clean --force

COPY . .

# Production
FROM node:20-alpine AS production

WORKDIR /app

RUN addgroup -g 1001 -S nodejs && \
  adduser -S nextjs -u 1001

COPY --from=builder --chown=nextjs:nodejs /app /app/

USER nextjs

EXPOSE $PORT

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:8080', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) })"

CMD [ "node", "app.js" ]