FROM nim:2.0.14-ubuntu-regular AS nimstage

RUN git clone https://github.com/emscripten-core/emsdk

RUN \
  cd emsdk && \
  ./emsdk install latest && \
  ./emsdk activate latest  && \
  export PATH=$PATH:/emsdk/upstream/emscripten

WORKDIR /nimapi

COPY BusinessRoad.nimble .

RUN nimble install -dy

COPY api/ api/

COPY pow/ pow/

COPY lang/ lang/

COPY page/ page/

RUN mkdir dist/public -p

RUN \
  export PATH=$PATH:/emsdk && \
  export PATH=$PATH:/emsdk/upstream/emscripten && \
  emcc --version && \
  nimble build -d:release

RUN ./brPage

FROM node:22-alpine AS nodestage

WORKDIR /nimapi

COPY --from=nimstage /nimapi/dist ./dist

COPY --from=nimstage /nimapi/page ./page

WORKDIR /nimapi/page

RUN npm install

RUN npm run build

FROM nginx:stable-alpine-slim

COPY --from=nodestage /nimapi/dist/public /var/www/html

COPY containers/nginx_rel.conf /etc/nginx/nginx.conf
