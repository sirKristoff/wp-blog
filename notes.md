# Notes

## `docker` commands

### Up and Down `compose`

```bash
docker compose up
docker compose down && docker volume prune -f
```

### Docker logs

```bash
docker compose logs -f --tail 100
```

### Secrets

#### [_How to use secrets in Docker Compose_](https://docs.docker.com/compose/use-secrets/)

```yaml
services:
  database:
    environment:
                                # \/ path where secret is mounted in container
      MYSQL_ROOT_PASSWORD_FILE: /run/secrets/mysql-root-password
      MYSQL_PASSWORD_FILE: /run/secrets/mysql-password
    secrets:
      - mysql-root-password   # name of the secret which service gets access to
      - mysql-password

secrets:
  mysql-root-password:
    file: ../secrets/mysql-root-password.psw   # path to secret file on HOST filesystem
  mysql-password: # \/ name of environment variable which content will be assigned to the secret
    environment: "MYSQL_PASSWORD"
```

#### [_Unsupported external secret_](https://github.com/docker/compose/issues/9139)

Docker Compose is targeting raw engine (not swarm mode) so does not support secrets created on swarm. Engine does not support secrets, so compose only can be used with "pseudo-secrets" as bind mounts.

To deploy a compose file to a Swarm cluster, you must use `docker stack` command.

### Configs

The location of the mount point within the container defaults to `/<config-name>` in Linux containers.

The source of the config is either `file` or `external`.

- **`file`**: The config is created with the contents of the file at the specified path.
- **`environment`**: The config content is created with the value of an environment variable.
- **`content`**: The content is created with the inlined value.
- **`external`**: If set to `true`, `external` specifies that this config has already been created. Compose does not attempt to create it, and if it does not exist, an error occurs.
- **`name`**: The name of the config object in the container engine to look up. This field can be used to reference configs that contain special characters. The name is used as is and will not be scoped with the project name.

#### [_Service's configs element_](https://docs.docker.com/compose/compose-file/05-services/#configs)

```yaml
services:
  database:
    configs:
      - source: database-mariadb.cnf     # Config name
        target: /etc/mysql/mariadb.cnf   # Container path

configs:
  database-mariadb.cnf:
    file: ./database/conf/mariadb.cnf    # Host path
```

#### [_Configs top-level elements_](https://docs.docker.com/compose/compose-file/08-configs/)

```yaml
configs:
  app_config:   # \/ inlined value of config
    content: |
      debug=${DEBUG}
      spring.application.admin.enabled=${DEBUG}
      spring.application.name=${COMPOSE_PROJECT_NAME}
```

```yaml
configs:
  http_config:
    external: true    # config has already been created by other entity
    name: "${HTTP_CONFIG_KEY}"   # the name of config object to look up
```

### Compose Develop

```yaml
services:
  nginx:
    develop:
      watch:
        - action: sync+restart
          path: ./nginx/etc/conf.d
          target: /etc/nginx/conf.d

  wordpress:
    develop:
      watch:
        # sync static content
        - action: sync
          path: ./webapp/html
          target: /var/www/html
          ignore:
            - wp-admin/

```

The `watch` attribute defines a list of rules that control automatic service updates based on local file changes.

`action` defines the action to take when changes are detected. If action is set to:

- **`rebuild`**, Compose rebuilds the service image based on the `build` section and recreates the service with the updated image.
  `rebuild` is ideal for compiled languages or as fallbacks for modifications to particular files that require a full image rebuild (e.g. `package.json`).
- **`sync`**, Compose keeps the existing service container(s) running, but synchronizes source files with container content according to the `target` attribute.
  `sync` is ideal for frameworks that support _"Hot Reload"_
- **`sync+restart`**, Compose synchronizes source files with container content according to the `target` attribute, and then restarts the container.
  `sync+restart` is ideal when config file changes, and you don't need to rebuild the image but just restart the main process of the service containers. It will work well when you update a database configuration or your `nginx.conf` file.

The `ignore` attribute can be used to define a list of patterns for paths to be ignored.

`path` attribute defines the path to source code (relative to the project directory) to monitor for changes. Updates to any file inside the path, which doesn't match any `ignore` rule, triggers the configured action.

### Copying files

#### Copy one file

```bash
docker cp 'database':'/etc/mysql/mariadb.conf'  './database/conf/mariadb.conf'
```

#### Copy recursively

```bash
docker cp 'database':'/etc/mysql/mariadb.conf.d/.'  './database/conf/mariadb.conf.d'
```

## Wordpress

### site backend

`localhost:8080/wp-admin`

### PHP my admin site

`localhost:8081`
usr: MYSQL_USER
pass: MYSQL_PASSWORD

## Configuring domain

```text
 ## Point subdomain to IP
A record:  77.237.21.31
 ## Point subdomain to this same server
CNAME record:  blog  pointer.ovh
```

## database

### make backup

```bash
 ## enable the binary log records
sed -i 's/#log_bin/log_bin/g' /etc/mysql/mariadb.conf.d/50-server.cnf

 ## backup all databases
mysqldump  --verbose --comments \
  --user=root --password=${MYSQL_ROOT_PASSWORD} \
  --databases ${MYSQL_DATABASE} \
  --add-drop-database --add-drop-trigger \
  --add-locks --lock-all-tables \
  --host=database --port=3306 --compress \
  | gzip --verbose --best --stdout \
  > /var/lib/mysql/${MYSQL_DATABASE}.sql.gz
  # --all-databases > /var/lib/mysql/all-databases.sql

 ## restore database
gzip --verbose --decompress --stdout \
  /var/lib/mysql/${MYSQL_DATABASE}.sql.gz \
  | mysql  --user=root --password=${MYSQL_ROOT_PASSWORD} \
  --host=database --port=3306 --compress
```

## Nginx

### docker container

Run container:

```bash
docker run -itd --name rproxy -p 80:80 nginx:latest
```

### Configuration

Default configuration:

```bash
/etc/nginx/conf.d/default.conf
```

Validate configuration file:

```bash
 ## shell cmd
nginx -t
 ## docker container
docker exec nginx nginx -t
```

Reload configuration:

```bash
 ## shell cmd
nginx -s reload
 ## docker container
docker exec nginx nginx -s reload
```

### Static sites

Fragment of `/etc/nginx/conf.d/default.conf`:

```properties
    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }
```

### Reverse proxy

Fragment of `/etc/nginx/conf.d/default.conf`:

```properties
    location /sample {
        proxy_pass http://127.0.0.1:8080/sample/;
    }
```

### subdomain reverse proxy

Fragment of `/etc/nginx/conf.d/default.conf`:

```properties
server {
    listen 80;
    server_name blog.pointer.ovh www.blog.pointer.ovh;
    location / {
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_pass http://wordpress:8080;
    }
}
```

Example `index.html` file:

```html
<h1>Hello from blog.pointer.ovh</h1>
```

### sites-available

`/etc/nginx/sites-available/blog.pointer.ovh`:

```properties
server {

    # Port 80 is used for incoming http requests
    listen 80;

    # The URL we want this server config to apply to
    server_name blog.pointer.ovh;

    # The document root of our site - i.e. where its files are located
    root /var/www/blog.pointer.ovh;

    # Which files to look for by default when accessing directories of our site
    index index.php index.html;
}
```

Activate site:

```bash
ln -s '/etc/nginx/sites-available/blog.pointer.ovh'  '/etc/nginx/sites-enabled/'
```

### HTTPS

[YT](https://www.youtube.com/watch?v=MVuJ5h2YQoQ)

## FTP

### 1. Dockerizing `vsftpd`

Create `vsftpd.conf` FTP configuration file e.q. copy from `/etc/vsftpd.conf`

In configuration file modify:

- `secure_chroot_dir=/var/run/vsftpd/empty` - comment
- `seccomp_sandbox=NO` - add

#### Docker file

```docker
FROM alpine:3.12

RUN apk add vsftpd

RUN adduser -D -h '/home/ftpuser' 'ftpuser'

COPY 'vsftpd.conf' '/etc/vsftpd/vsftpd.conf'

EXPOSE 20 21

CMD [ "vsftpd", "/etc/vsftpd/vsftpd.conf" ]
```

#### Build docker image

```bash
ls './Dockerfile' './vsftpd.conf'
docker build -t vsftpd '.'
```

#### Run docker container

```bash
docker run -p 20:20 -p 21:21 -d vsftpd
```

### 2. Public docker image `delfer/alpine-ftp-server`

#### Docker-compose

```yaml
services:
  ftp:
    image: delfer/alpine-ftp-server
    ports:
      - 21:21
      - 21000-21010:21000-21010
    environment:
      - USER=ftp_user|ftp_password|/home/ftp_user|10001
    volumes:
      - ./ftp-data:/home/ftp_user
```

#### Change privileges for _host_ FTP directory

No other user will be able to read _home_ directory.

```bash
sudo chmod -R go-rx ./ftp-data
```

### 3. `garethflowers/ftp-server`

[github](https://github.com/garethflowers/docker-ftp-server)
