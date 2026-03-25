# Use the official Node.js 24 Alpine image as the base
ARG NODE=node:24-alpine

FROM $NODE AS base

# Update and install necessary packages
RUN apk update \
    && apk upgrade \
    && rm -rf /var/cache/apk/*

# Set the working directory
WORKDIR /app

# Copy package files
COPY package.json pnpm-lock.yaml ./

# Install pnpm
RUN npm install -g pnpm

# Install dependencies
RUN pnpm install --frozen-lockfile

# Copy the rest of the application code
COPY . .

# Generate Prisma client
RUN pnpm prisma generate

# Build the application
RUN pnpm build

# Production stage
FROM $NODE AS production

# Update and install curl for health checks
RUN apk add --no-cache curl

# Set the working directory
WORKDIR /app

# Create non-root user and group
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nestjs

# Copy package files
COPY package.json pnpm-lock.yaml ./

# Install only production dependencies
RUN npm install -g pnpm && pnpm install --frozen-lockfile --prod

# Copy the generated Prisma client from the build stage
COPY --from=base --chown=nestjs:nodejs /app/node_modules/.prisma ./node_modules/.prisma

# Copy the built application from the base stage
COPY --from=base --chown=nestjs:nodejs /app/dist ./dist

# Copy Prisma schema and migrations if needed at runtime
COPY --from=base --chown=nestjs:nodejs /app/prisma ./prisma

# Set user to the non-root user
USER nestjs

# Expose the port the app runs on
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/ || exit 1

# Command to run the application
CMD ["node", "dist/main.js"]
