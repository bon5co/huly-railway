# huly-railway

Wrapper images that let Huly (open-source project management platform, 0.7.426) run as a Railway template.

- `Dockerfile.gateway` - nginx gateway on Railway's injected port, plus the bootstrap that creates the first administrator and workspace from variables (built on the upstream `hardcoreeng/tool` image).
- `Dockerfile.elastic` - Elasticsearch 7.14.2 with the ingest-attachment plugin and a root-owned-volume entrypoint.

Published to `ghcr.io/bon5co/huly-railway-gateway` and `ghcr.io/bon5co/huly-railway-elastic`.
