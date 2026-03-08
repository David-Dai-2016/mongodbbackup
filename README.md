# mongobackup

#start it

docker compose up -d --build

#test it once manually

docker compose run --rm mongodb-backup /app/mongodb-backup.sh

#watch logs

docker compose logs -f mongodb-backup

#folder structure
.
├─ .env
├─ docker-compose.yml
├─ Dockerfile
├─ crontab
├─ mongodb-backup.sh
├─ backup-data/
└─ logs/
