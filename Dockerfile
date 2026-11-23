# RSS-Bridge for Railway.
# Official image, pinned by version tag and multi-arch index digest.
FROM rssbridge/rss-bridge:2026-09-30@sha256:fbb324d75613b90dad7394c385cee361a31f38e04f1ee9089a4758795b1104c3

# Size nginx and PHP-FPM for a small Railway service (0.5 GB / 1 vCPU) instead of the host's CPU count.
RUN sed -i 's/^worker_processes .*/worker_processes 2;/' /etc/nginx/nginx.conf \
 && printf '[www]\npm = dynamic\npm.max_children = 3\npm.start_servers = 2\npm.min_spare_servers = 1\npm.max_spare_servers = 2\npm.max_requests = 500\n' \
      > /etc/php/8.2/fpm/pool.d/zz-railway.conf

COPY nginx.conf.template /etc/rss-bridge/nginx.conf.template
COPY railway-start.sh /usr/local/bin/railway-start.sh
RUN chmod 0755 /usr/local/bin/railway-start.sh

ENV PORT=8080 \
    RSSBRIDGE_DATA_DIR=/data
EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/railway-start.sh"]
