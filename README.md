yum install -y gcc glibc glibc-devel readline-devel zlib-devel


groupadd postgres
useradd -g postgres -C "Postgres Databaes Service" -s /sbin/nologin -d /var/lib/postgres -m postgres

mkdir -p /data/apps/postgresql/data
chown postgres.postgres -R /data/apps/postgresql/


./configure --prefix=/data/apps/postgresql/ --without-readline
su  postgres

/data/apps/postgresql/bin/initdb  -D /data/apps/postgresql/data
/data/apps/postgresql/bin/pg_ctl -D /data/apps/postgresql/data/ -l /data/apps/postgresql/logs/logfile start
cp contrib/start-scripts/linux /www/server/postgresql/init.d/postgresql

mkdir -p /pg/data/

mkdir -p /pg/archive/
mkdir -p /pg/backup/


revoke all on database wiki from wiki;
DROP user wiki;
