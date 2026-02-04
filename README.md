# Gitbucket Docker

This is repo to create a docker image for running Gitbucket.

Designed to be used in a full stack: `nginx - gitbucket - postgresdb`

## Quickstart

1. Create a orchestration repo `gitbucket-ci`, containing `docker-compose.yml` in
   the root dir.

1. Using git submodules, create a submodule inside the ci repo.
   `git submodule add {repo} src-gitbucket`

1. Set up the `.env` files.

1. Run the full stack using `docker compose up`.

## References

### Docker compose

```yaml
services:

  nginx:
    restart: unless-stopped
    container_name: ${PROJECT_NAME}_nginx
    build:
      context: ./src-nginx
      args:
        url_docker: ${url_docker_index}
    environment:
      - NGINX_ENVSUBST_TEMPLATE_SUFFIX=.template
      - NGINX_ENVSUBST_TEMPLATE_DIR=/etc/nginx/templates
      - NGINX_ENVSUBST_OUTPUT_DIR=/etc/nginx/conf.d
      - SHARED_DATA_DIR=${SHARED_DATA_DIR}
      - NGINX_LOG_FOLDER=${SHARED_LOGS_DIR}/nginx/
      - NGINX_STATIC_FOLDER=${SHARED_DATA_DIR}/www/static/
      - NGINX_MEDIA_FOLDER=${SHARED_DATA_DIR}/www/media/
      - NGINX_PORT_HTTP=${NGINX_PORT_HTTP}
      - NGINX_PORT_HTTPS=${NGINX_PORT_HTTPS}
      - GITBUCKET_PORT=${GITBUCKET_PORT}
      - GITBUCKET_PREFIX=${GITBUCKET_PREFIX}
      - DRAWIO_PREFIX=${DRAWIO_PREFIX:-drawio}
      - DRAWIO_PORT=${DRAWIO_PORT:-8080}
    ports:
      - "${NGINX_PORT_HTTP}:${NGINX_PORT_HTTP}"
      - "${NGINX_PORT_HTTPS}:${NGINX_PORT_HTTPS}"
    volumes:
      - ./src-nginx/templates:/etc/nginx/templates
      - datashare:/datashare
      - appcache_nginx:/var/cache/nginx
    networks:
      - appnet

  pgdb:
    container_name: ${PROJECT_NAME}_pgdb
    restart: unless-stopped
    env_file:
      - ./src-pgdb/.env.docker
    build:
      context: ./src-pgdb
      args:
        url_docker: ${url_docker_index}
    ports:
      - "$PGDB_PORT:$PGDB_PORT"
    command:
      - postgres
      - "-p"
      - ${PGDB_PORT}
    volumes:
      # - dbdata_pgdb:/var/lib/postgresql/data # postgresql 17
      - dbdata_pgdb:/var/lib/postgresql/18/docker # postgresql 18
    networks:
      - appnet

  gitbucket:
    restart: unless-stopped
    environment:
      - GITBUCKET_DB_URL=jdbc:postgresql://pgdb:${PGDB_PORT}/gitbucket
      - GITBUCKET_DB_DRIVER=org.postgresql.Driver
      - GITBUCKET_PORT=${GITBUCKET_PORT}
      - GITBUCKET_PREFIX=${GITBUCKET_PREFIX}
    container_name: ${PROJECT_NAME}_gitbucket
    build:
      context: ./src-gitbucket
      args:
        url_docker: ${url_docker_index}
    env_file:
      - ./src-gitbucket/.env.docker
    volumes:
      - data_gitbucket:/gitbucket
    networks:
      - appnet

  drawio:
    image: ${url_docker_index}/jgraph/drawio:29.3.6
    container_name: ${PROJECT_NAME}_drawio
    restart: unless-stopped
    networks:
      - appnet

networks:
  appnet:


volumes:
  datashare:
  data_gitbucket:
  dbdata_pgdb:
  applogs:
  appcache_nginx:

```

## Wiki

### External db configurations

[Wiki for external db](https://github.com/gitbucket/gitbucket/wiki/External-database-configuration)

#### PosgreSQL init

```bash
sudo su - postgres
psql
```

```sql
CREATE DATABASE gitbucket;
CREATE USER gitbucket_user WITH ENCRYPTED PASSWORD 'YOUR_PASSWORD!';
GRANT ALL PRIVILEGES ON DATABASE gitbucket TO gitbucket_user;
GRANT CONNECT ON database gitbucket to gitbucket_user;
GRANT ALL ON SCHEMA public TO gitbucket_user; -- Required for postgresql >= 15
```

```json
db {
  url = "jdbc:postgresql://localhost/gitbucket"
  user = "gitbucket_user"
  password = "YOUR_PASSWORD!"
}
```

#### PosgreSQL Migrations

First, migrate using the UI > import/export.

Then,

```bash
sudo su - postgres
psql gitbucket < gitbucket-export-xxxx.sql
```

```sql
SELECT setval('label_label_id_seq', (select max(label_id) + 1 from label));
SELECT setval('access_token_access_token_id_seq', (select max(access_token_id) + 1 from access_token));
SELECT setval('commit_comment_comment_id_seq', (select max(comment_id) + 1 from commit_comment));
SELECT setval('commit_status_commit_status_id_seq', (select max(commit_status_id) + 1 from commit_status));
SELECT setval('milestone_milestone_id_seq', (select max(milestone_id) + 1 from milestone));
SELECT setval('issue_comment_comment_id_seq', (select max(comment_id) + 1 from issue_comment));
SELECT setval('ssh_key_ssh_key_id_seq', (select max(ssh_key_id) + 1 from ssh_key));
SELECT setval('priority_priority_id_seq', (select max(priority_id) + 1 from priority));
SELECT setval('release_asset_release_asset_id_seq', (select max(release_asset_id) + 1 from release_asset));

-- GitBucket 4.33.0 or before
SELECT setval('activity_activity_id_seq', (select max(activity_id) + 1 from activity));
```
