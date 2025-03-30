FROM node:18-alpine AS build

WORKDIR /app

COPY package*.json ./
RUN npm ci --quiet

COPY . .

COPY .env.deploy .env

RUN npm run build-only

FROM nginx:alpine AS production

COPY docker/nginx.conf /etc/nginx/conf.d/default.conf

COPY --from=build /app/dist /usr/share/nginx/html

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost/health || exit 1

RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup && \
    chown -R appuser:appgroup /usr/share/nginx/html

USER appuser

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]