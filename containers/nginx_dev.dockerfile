FROM nginx:stable-alpine-slim

COPY nginx_dev.conf /etc/nginx/nginx.conf
