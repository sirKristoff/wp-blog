## Up and Down Wordpress

```bash
docker compose up
docker compose down && docker volume prune -f
```

### site backend

`localhost:8080/wp-admin`

### PHP my admin site

`localhost:8081`
usr: MYSQL_USER
pass: MYSQL_PASSWORD

## Configuring domain

```
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

Defaul configuration:
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
```conf
    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }
```

### Reverse proxy 

Fragment of `/etc/nginx/conf.d/default.conf`:
```conf
    location /sample {
        proxy_pass http://127.0.0.1:8080/sample/;
    }
```

### subdomain reverse proxy

Fragment of `/etc/nginx/conf.d/default.conf`:
```conf
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
```conf
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
