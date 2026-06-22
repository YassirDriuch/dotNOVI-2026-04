# Single-stage Dockerfile for dotNOVI application
# This is the student version for Learning Docker

FROM node:20-alpine

# Metadata
LABEL maintainer="NOVI Hogeschool"
LABEL description="dotNOVI - Node.js application for NOVI DevOps course"

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install production dependencies
RUN npm ci

# Copy application code
COPY src ./src

# Don't run as root (security best practice)
USER node

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)})"

# Expose port
EXPOSE 3000

# Run application
CMD ["node", "src/index.js"]
