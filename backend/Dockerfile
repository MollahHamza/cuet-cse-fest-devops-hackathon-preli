# Multi-stage build for production
FROM node:20-alpine AS base
WORKDIR /app
COPY package*.json ./

# Build stage - install all dependencies and compile TypeScript
FROM base AS build
RUN npm install
COPY . .
RUN npm run build

# Production dependencies stage
FROM base AS dependencies
RUN npm install --production && npm cache clean --force

# Production stage
FROM node:20-alpine AS production
RUN addgroup -g 1001 -S nodejs && adduser -S nodejs -u 1001
WORKDIR /app
COPY --from=dependencies --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=build --chown=nodejs:nodejs /app/dist ./dist
COPY --chown=nodejs:nodejs package*.json ./
USER nodejs
EXPOSE 3847
ENV NODE_ENV=production
CMD ["npm", "start"]






