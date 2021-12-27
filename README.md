# zypress.db
zypress postgres database

### Docker compose force rebuild everytime

```
docker-compose down && docker-compose build --no-cache && docker-compose up --force-recreate
```

### Do this for `gotrue` app to run properly

```
ALTER ROLE zypress_user SET search_path = "$user", auth, public;
```
