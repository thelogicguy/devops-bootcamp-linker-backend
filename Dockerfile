# Use the official Node.js 24 Alpine image as the base
ARG NODE=node:24-alpine

FROM $NODE AS base

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

# Set the working directory
WORKDIR /app

# Install runtime dependencies only
RUN apk add --no-cache openssl curl netcat-openbsd

# Create non-root user and group
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nestjs

# Copy package files and Prisma schema
COPY package.json pnpm-lock.yaml ./
COPY prisma ./prisma

# Install only production dependencies and generate Prisma client
RUN npm install -g pnpm && pnpm install --prod --frozen-lockfile && pnpm prisma generate

# Copy the built application from the base stage
COPY --from=base --chown=nestjs:nodejs /app/dist ./dist

# Set environment variables
ENV PORT=3001

# Copy entrypoint script and make it executable
COPY --from=base --chown=nestjs:nodejs /app/db-script.sh ./db-script.sh
RUN chmod +x ./db-script.sh

# Set user to the non-root user
USER nestjs

# Expose the port the app runs on
EXPOSE 3001

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:3001/api || exit 1

# Command to run the application
CMD ["./db-script.sh"]
