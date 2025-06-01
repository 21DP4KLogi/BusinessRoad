FROM nim:2.0.8-regular AS powstage

RUN \
  git clone https://github.com/emscripten-core/emsdk && \
  cd emsdk && \
  ./emsdk install latest && \
  ./emsdk activate latest
WORKDIR /app
COPY BusinessRoad.nimble .
RUN nimble install -dy
COPY pow/ pow/
RUN mkdir dist/public -p
RUN \
  export PATH=$PATH:/emsdk && \
  export PATH=$PATH:/emsdk/upstream/emscripten && \
  emcc --version && \
  nimble build brPow


FROM nim:2.0.8-alpine AS nimstage

WORKDIR /app
COPY BusinessRoad.nimble .
COPY api/ api/
COPY lang/ lang/
COPY page/ page/
COPY --from=powstage /app/dist ./dist
RUN nimble install -dy
RUN nimble run brPage


FROM node:22-alpine AS nodestage

WORKDIR /app
COPY page/ page/
COPY --from=nimstage /app/dist ./dist
WORKDIR /app/page
RUN npm install
RUN npm run build-compat


FROM nginx:stable-alpine-slim

COPY containers/nginx_rel.conf /etc/nginx/nginx.conf
COPY --from=nodestage /app/dist/public /var/www/html
