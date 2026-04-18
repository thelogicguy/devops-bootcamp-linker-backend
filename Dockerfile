# syntax=docker/dockerfile:1.4
FROM node:24-alpine AS base

WORKDIR /app

# Build dependencies (only needed for native modules)
RUN apk add --no-cache python3 build-base openssl

RUN npm install -g pnpm@latest

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

COPY . .

# Explicit Prisma binary target for Alpine (musl)
ENV PRISMA_CLI_BINARY_TARGETS=linux-musl-openssl-3.0.x
RUN pnpm prisma generate && pnpm build

# --- Production stage ---
FROM node:24-alpine AS production

LABEL org.opencontainers.image.source="https://github.com/thelogicguy/devops-bootcamp-linker-backend.git"

ENV NODE_ENV=production \
    PORT=3001 \
    PRISMA_CLI_BINARY_TARGETS=linux-musl-openssl-3.0.x

RUN apk add --no-cache curl --no-cache

WORKDIR /app

RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nestjs

# Copy pnpm from base instead of reinstalling
COPY --from=base /usr/local/lib/node_modules/pnpm /usr/local/lib/node_modules/pnpm
RUN ln -s /usr/local/lib/node_modules/pnpm/bin/pnpm.cjs /usr/local/bin/pnpm

COPY package.json pnpm-lock.yaml ./
COPY prisma ./prisma

# Install prod deps and generate Prisma client
RUN pnpm install --prod --frozen-lockfile && pnpm prisma generate

COPY --from=base --chown=nestjs:nodejs /app/dist ./dist

USER nestjs

EXPOSE 3001

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:3001/api || exit 1

# Exec form for proper SIGTERM handling — migrations should run separately
CMD ["node", "dist/main.js"]