# Stage 1: build
FROM node:20-bullseye-slim AS builder
WORKDIR /app

# Copy package files and install dependencies (use npm ci if package-lock.json exists)
COPY package*.json ./
RUN npm ci

# Copy all and build
COPY . .
RUN npm run build

# Stage 2: runtime
FROM node:20-bullseye-slim AS runner
WORKDIR /app
ENV NODE_ENV=production

# Copy package.json & node_modules from builder
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/next.config.mjs ./next.config.mjs
# If you use SSR pages that require extra files, copy them (e.g., server files)

EXPOSE 3000
CMD ["npm","run","start"]
