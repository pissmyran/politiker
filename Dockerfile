# PolitikerKontakt as a self-hosted container. Build from the repo root:
#   docker build -t politiker .
# The Worker, its queue, cron and Durable Object run in workerd (the
# Cloudflare Workers runtime) through `wrangler dev --local`; D1, KV and R2
# live under /data. The contact directory starts empty. The source has only
# placeholders; the entrypoint fills them in from the container environment.
FROM node:26.12.1-trixie-slim@sha256:94816674c62774da0d099a947bf4613b9e1972a2733abd0d0cd80e795f8411d0

ENV NODE_ENV=production \
    WRANGLER_SEND_METRICS=false \
    PORT=8787

WORKDIR /opt/app
COPY app/package.json app/package-lock.json app/
RUN cd app && npm ci --no-audit --no-fund && npm cache clean --force
COPY tools ./tools
COPY app/src app/src
COPY app/public app/public
COPY app/tsconfig.json app/
COPY shared shared
COPY infra/migrations infra/migrations
COPY cloudflare.example.env ./
COPY docker docker

RUN mkdir -p /data /srv && chown -R node:node /data /srv /opt/app/app/node_modules
USER node
VOLUME /data
EXPOSE 8787

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s \
  CMD node -e "fetch('http://127.0.0.1:'+process.env.PORT+'/').then(r=>process.exit(r.status<500?0:1)).catch(()=>process.exit(1))"

ENTRYPOINT ["/opt/app/docker/entrypoint.sh"]
