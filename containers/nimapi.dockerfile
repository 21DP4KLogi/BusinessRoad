FROM nim:2.0.8-alpine AS buildstage

WORKDIR /app
COPY BusinessRoad.nimble .
RUN nimble install -dy
COPY api/ api/
COPY pow/ pow/
COPY lang/ lang/
COPY page/ page/
RUN nimble build -d:release -d:useMalloc brApi


FROM nim:2.0.8-alpine

WORKDIR /app
RUN apk add libpq
COPY --from=buildstage /app/brApi .
CMD ./brApi
