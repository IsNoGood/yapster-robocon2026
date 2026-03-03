# Backend Dockerfile
FROM node:22-alpine AS build

WORKDIR /app

# Copy root package files (workspace)
COPY package*.json ./

# Copy backend package files
COPY backend/package*.json ./backend/
COPY backend/tsconfig.json ./backend/

# Install all dependencies (workspace aware)
RUN npm ci

# Copy backend source code
COPY backend/src ./backend/src

# Build TypeScript to JavaScript
WORKDIR /app/backend
RUN npm run build

# Production stage
FROM node:22-alpine AS production

WORKDIR /app

# Copy root package files
COPY package*.json ./

# Copy backend package files
COPY backend/package*.json ./backend/

# Install production dependencies (workspace aware)
RUN npm ci --omit=dev

# Copy built application from build stage
COPY --from=build /app/backend/dist ./backend/dist

# Set working directory to backend
WORKDIR /app/backend

# Expose port
EXPOSE 3000

# Set environment to production
ENV NODE_ENV=production

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Start the backend server
CMD ["node", "dist/server.js"]
