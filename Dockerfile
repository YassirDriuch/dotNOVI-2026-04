# FROM: Base image starten
FROM node:20-alpine AS build

# LABEL: Metadata
LABEL maintainer="Yassir"

# WORKDIR: Werkmapje in container
WORKDIR /app

# COPY: Bestanden van host naar container
COPY package*.json ./

# RUN: Commando's uitvoeren
RUN npm ci --only=production


FROM node:20-alpine
WORKDIR addgroup -g 1001 nodejs && adduser -S nodejs -u 1001

# COPY: Meer bestanden
COPY --from=build --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --chown=nodejs:nodejs src ./src src ./src

USER nodejs

# HEALTHCHECK: Health monitoring
HEALTHCHECK --interval=30s CMD ...

# EXPOSE: Port declaratie
EXPOSE 3000

# CMD: Default command
CMD ["node", "src/index.js"]
