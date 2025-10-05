# Dockerfile for AstroSynth Web App
# Multi-stage build: Build Flutter web app, then serve with Nginx

# Stage 1: Build Flutter web app
FROM ghcr.io/cirruslabs/flutter:stable AS build

# Set working directory
WORKDIR /app

# Copy pubspec files
COPY pubspec.yaml pubspec.lock ./

# Get dependencies
RUN flutter pub get

# Copy the rest of the application
COPY . .

# Build web app for production
RUN flutter build web --release --web-renderer canvaskit

# Stage 2: Serve with Nginx
FROM nginx:alpine

# Copy custom Nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Copy built Flutter web app from build stage
COPY --from=build /app/build/web /usr/share/nginx/html

# Expose port 8080 (Render requires this port)
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:8080/ || exit 1

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
