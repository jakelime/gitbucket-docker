#!/bin/sh
set -e

# 1. Create directory (idempotent)
mkdir -p /gitbucket/plugins

# 2. Copy baked plugins to the volume (update mode)
#    This moves plugins from the image's staging area to the actual running directory
cp -u /opt/baked-plugins/* /gitbucket/plugins/

# 3. Start the application
exec java -jar /opt/gitbucket.war
