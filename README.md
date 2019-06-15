This is a simple perl script that mimics the behavior of [koreader/koreader-sync-server](https://github.com/koreader/koreader-sync-server) for a single user. I wrote it because I don't want to run a whole docker container and I'm too lazy to figure out how to get the official server running. Configure it by setting the username and password (password should be an md5sum), and create the sqlite database with the schema in the script. I run it using fcgi in nginx, but it should also work fine with Apache.

Nginx config:

```
location ~ ^(.+\.pl)(.)$ {
  fastcgi_split_path_info ^(.+\.pl)(.*)$;
  fastcgi_pass unix:/run/fcgiwrap.sock;
  fastcgi_index index.pl;
  fastcgi_param SCRIPT_FILENAME $document_root$fastctgi_script_name;
  fastcgi_param PATH_INFO $fastcgi_path_info;
  include fastcgi_params;
}
```
