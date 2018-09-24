#!/bin/ash
# setup MariaDB if no mysql database found
if [ ! -d "$MYSQL_DATABASE/mysql" ]; then
	#10.3 parameters change
	/usr/bin/mysql_install_db --defaults-extra-file==$MYSQL_EXTRA/my.cnf --user=mysql --datadir=$MYSQL_DATABASE --skip-test-db
fi
# run mysql database
/usr/bin/mysqld_safe --defaults-extra-file=$MYSQL_EXTRA/my.cnf --user=mysql --datadir=$MYSQL_DATABASE
