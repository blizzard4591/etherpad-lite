# Etherpad Lite Dockerfile
#
# https://github.com/ether/etherpad-lite
#
# Author: muxator

FROM node:10-buster-slim
LABEL maintainer="Etherpad team, https://github.com/ether/etherpad-lite"

# plugins to install while building the container. By default no plugins are
# installed.
# If given a value, it has to be a space-separated, quoted list of plugin names.
#
# EXAMPLE:
#   ETHERPAD_PLUGINS="ep_codepad ep_author_neat"
ARG ETHERPAD_PLUGINS="ep_tables2 ep_hash_auth ep_image_upload"

# Set the following to production to avoid installing devDeps
# this can be done with build args (and is mandatory to build ARM version)
#ENV NODE_ENV=development
ENV NODE_ENV=production

# Get Etherpad-lite's other dependencies
RUN apt-get update \
  && apt-get install -y sqlite3 \
  && apt-get install -y abiword sudo

# Add Sudo for abiword
RUN echo "etherpad ALL = NOPASSWD: /usr/bin/abiword" >> /etc/sudoers

# Follow the principle of least privilege: run as unprivileged user.
#
# Running as non-root enables running this image in platforms like OpenShift
# that do not allow images running as root.
RUN useradd --uid 5001 --create-home etherpad

RUN mkdir /opt/etherpad-lite && chown etherpad:etherpad /opt/etherpad-lite

USER etherpad:etherpad

WORKDIR /opt/etherpad-lite

COPY --chown=etherpad:etherpad ./ ./

# install node dependencies for Etherpad
RUN bin/installDeps.sh && \
	rm -rf ~/.npm/_cacache

# Install the plugins, if ETHERPAD_PLUGINS is not empty.
#
# Bash trick: in the for loop ${ETHERPAD_PLUGINS} is NOT quoted, in order to be
# able to split at spaces.
RUN for PLUGIN_NAME in ${ETHERPAD_PLUGINS}; do npm install "${PLUGIN_NAME}"; done

# Copy the configuration file.
COPY --chown=etherpad:etherpad ./settings.json.docker /opt/etherpad-lite/settings.json

RUN npm install sqlite3

# Allow changes to settings.conf as well as the Sqlite database being persistent.
VOLUME /opt/etherpad-lite/var

EXPOSE 9001
CMD ["node", "node_modules/ep_etherpad-lite/node/server.js"]
