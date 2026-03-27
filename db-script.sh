#!/bin/sh

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to start..."

until nc -z postgres 5432; do
  sleep 2
done

echo "PostgreSQL started"

# Run Prisma migrations
pnpm prisma migrate deploy

# Start NestJS application
node dist/main.js