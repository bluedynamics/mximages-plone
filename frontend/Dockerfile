FROM node:20-slim

LABEL maintainer="Jens Klein <jk@kleinundpartner.at>" \
      org.label-schema.name="mx-plone-image-frontend" \
      org.label-schema.description="BlueDynamics MX Plone Image Frontend" \
      org.label-schema.vendor="BlueDynamics Alliance"

ARG CI_JOB_TOKEN

# prepare and cleanup
RUN \
  useradd --system -m -d /app -U -u 500 plone &&\
  apt-get update &&\
  buildDeps="busybox wget git ca-certificates make" &&\
  apt-get install -y --no-install-recommends $buildDeps &&\
  busybox --install -s &&\
  apt-get -y clean &&\
  corepack enable

USER plone

# Add local code
COPY --chown=plone:plone . /app
WORKDIR /app

# Install and build application
RUN \
  corepack install &&\
	pnpm dlx mrs-developer missdev --hard --no-config --fetch-https &&\
  pnpm install &&\
  pnpm build &&\
  echo "Y" | pnpm prune --prod --no-optional &&\
  rm -rf .cache .local/share/pnpm/store &&\
  find . -name .git -exec rm -rfv {} +

# Expose default Express port
EXPOSE 3000

# Set healthcheck to port 3000
HEALTHCHECK --interval=10s --timeout=5s --start-period=30s CMD [ -n "$LISTEN_PORT" ] || LISTEN_PORT=3000 ; wget -q http://127.0.0.1:"$LISTEN_PORT" -O - || exit 1

# disables health check if uncommented
# HEALTHCHECK --interval=10s --timeout=5s --start-period=60s CMD exit 0

# Entrypoint would be pnpm
ENTRYPOINT [ "pnpm" ]

# And the image will run in production mode
CMD ["start:prod"]