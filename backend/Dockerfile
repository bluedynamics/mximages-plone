# syntax=docker/dockerfile:1
FROM python:3.12-slim-bookworm

LABEL maintainer="Jens Klein <jk@kleinundpartner.at>" \
      org.label-schema.name="mx-plone-image-backend" \
      org.label-schema.description="BlueDynamics MX Plone Image Backend" \
      org.label-schema.vendor="BlueDynamics Alliance"

# Python optimization for OCI images: no bytecode writing
ENV PYTHONDONTWRITEBYTECODE 1

# Set VENV instructions for mxmake
ENV VENV_CREATE false
ENV VENV_FOLDER /venv
ENV VIRTUAL_ENV /venv

# use UV for pip in mxmake
ENV MXENV_UV_GLOBAL true

# configure zope-configuration
ENV COOKIECUTTER_ZOPE_INSTANCE_VERSION 2.1.1
ENV ZOPE_TEMPLATE /site/deployment/cookiecutter-zope-instance.zip
ENV ZOPE_CONFIGURATION_FILE /site/deployment/instance-from-environment.yaml
ENV ZOPE_TEMPLATE_CHECKOUT=
ENV ZOPE_BASE_FOLDER /

# presets for ZOPE
ENV INSTANCE_target /instance
ENV INSTANCE_debug_mode "false"

# prepare and cleanup
RUN \
  useradd --system -m -d /app -U -u 500 plone &&\
  apt-get update &&\
  apt-get -y upgrade &&\
  buildDeps="make busybox ca-certificates curl git gosu libmagic1 wget" &&\
  apt-get install -y --no-install-recommends $buildDeps &&\
  busybox --install -s &&\
  # global uv
  pip install uv &&\
  # create venv for plone
  uv venv /venv &&\
  # install psycopg2, needs buildessential libpq-dev
  psycopg2RuntimeDeps="libpq5" &&\
  psycopg2BuildDeps="build-essential libpq-dev" &&\
  apt-get install -y --no-install-recommends $psycopg2RuntimeDeps $psycopg2BuildDeps &&\
  uv pip install -p /venv/bin/python psycopg2 &&\
  apt-get remove -y $psycopg2BuildDeps &&\
  apt-get autoremove -y &&\
  # create a data folder
  mkdir /instance &&\
  # give permissions
  chown -R plone:plone /venv /instance &&\
  # cleanup
  apt-get -y clean &&\
  pip cache purge

USER plone

# Add local code
COPY --chown=plone:plone ./backend /site
WORKDIR /site
RUN \
  sed -i 's/\[test\]/\[production\]/g' /site/requirements.txt &&\
  ls -la &&\
  make packages cookiecutter &&\
  mkdir /site/deployment &&\
  wget -O $ZOPE_TEMPLATE https://github.com/plone/cookiecutter-zope-instance/archive/refs/tags/${COOKIECUTTER_ZOPE_INSTANCE_VERSION}.zip &&\
  wget -O deployment/transform_from_environment.py https://raw.githubusercontent.com/plone/cookiecutter-zope-instance/${COOKIECUTTER_ZOPE_INSTANCE_VERSION}/helpers/transform_from_environment.py &&\
  chmod u+x deployment/transform_from_environment.py &&\
  find /venv -name LC_MESSAGES -exec chown plone:plone {} + &&\
  find /venv \( -type f -a -name '*.pyc' -o -name '*.pyo' \) -exec rm -rf '{}' + &&\
  uv cache clean

HEALTHCHECK --interval=10s --timeout=5s --start-period=60s CMD [ -n "${INSTANCE_wsgi_listen}" ] || INSTANCE_wsgi_listen=127.0.0.1:8080 ; wget -q http://"${INSTANCE_wsgi_listen}"/ok -O - | grep OK || exit 1

# disables health check if uncommented
# HEALTHCHECK --interval=10s --timeout=5s --start-period=60s CMD exit 0

ENTRYPOINT ["/site/scripts/entrypoint.sh"]
CMD ["start"]
