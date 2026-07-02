# Статический деплой приглашения на Railway через Caddy.
# Сборки нет — просто кладём готовые файлы в образ и раздаём Caddy.
FROM caddy:2-alpine

# Конфиг сервера.
COPY Caddyfile /etc/caddy/Caddyfile

# Сайт: index.html + ассеты, которые обязаны лежать рядом.
# (music.mp3 опционален — если появится в репозитории, тоже скопируется.)
COPY index.html og-image.png atmos.mp4 /srv/

CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
