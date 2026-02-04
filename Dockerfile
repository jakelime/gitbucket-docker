FROM eclipse-temurin:17.0.17_10-jre-noble

# Install git, a required package for commit graph to work
RUN apt-get update && apt-get install -y \
    git \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# 1. Download War
ADD https://github.com/gitbucket/gitbucket/releases/download/4.45.0/gitbucket.war /opt/gitbucket.war

# 2. Symlink
RUN ln -s /gitbucket /root/.gitbucket

# 3. Copy plugins to a STAGING directory (Safe from volume overwrites)
#    Note: path is relative to the build context (./src-gitbucket)
COPY plugins/ /opt/baked-plugins/

# 4. Copy the entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

# 5. Make the script executable
RUN chmod +x /usr/local/bin/entrypoint.sh

# 6. Set the script to run on startup
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]