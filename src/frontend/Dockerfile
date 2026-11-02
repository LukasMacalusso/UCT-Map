FROM node:22-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
ARG VITE_MAPBOX_TOKEN
ENV VITE_MAPBOX_TOKEN=$VITE_MAPBOX_TOKEN
RUN npm run build

FROM nginx:alpine
ARG API_GATEWAY_URL=http://api-gateway:8080
COPY nginx.conf /etc/nginx/conf.d/default.conf
RUN sed -i "s|\${API_GATEWAY_URL}|${API_GATEWAY_URL}|g" /etc/nginx/conf.d/default.conf && \
    sed -i "s|/var/run/nginx.pid|/tmp/nginx.pid|g; s|/run/nginx.pid|/tmp/nginx.pid|g" /etc/nginx/nginx.conf
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
