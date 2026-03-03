# Frontend Dockerfile
FROM node:22-alpine AS build

WORKDIR /app

# Copy root package files (workspace)
COPY package*.json ./

# Copy frontend package files
COPY frontend/package*.json ./frontend/

# Install all dependencies (workspace aware)
RUN npm ci

# Copy frontend source code
COPY frontend ./frontend

# Build for production
WORKDIR /app/frontend
RUN npm run build

# Production stage - use nginx to serve static files
FROM nginx:alpine AS production

# Copy built assets from build stage
COPY --from=build /app/frontend/dist /usr/share/nginx/html

# Copy nginx configuration
COPY frontend/nginx.conf /etc/nginx/conf.d/default.conf

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost/health || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
