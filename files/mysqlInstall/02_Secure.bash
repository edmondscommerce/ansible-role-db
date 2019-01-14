#!/usr/bin/env bash
readonly DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
cd $DIR;
set -e
set -u
set -o pipefail
standardIFS="$IFS"
IFS=$'\n\t'
echo "
===========================================
$(hostname) $0 $@
===========================================
"

if [[ "$(whoami)" != "root" ]]
then
    echo "Please run this as root"
    exit 1
fi

perconaGeneratedPass="$(cat /var/log/mysqld.log |grep generated | cut -d ':' -f 4 | xargs)"

mysqlRootPassword="@$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32;echo;)"


echo "---------------------------------------"
echo "MySQL root Password: $mysqlRootPassword"
echo "---------------------------------------"

mysqladmin -p"$perconaGeneratedPass" -u root password "$mysqlRootPassword"

echo "Done"

echo "Configuring .my.cnf Files"
echo "
[client]
user=root
password=$mysqlRootPassword
"   > ~/.my.cnf
chmod 600 ~/.my.cnf

echo "Securing MySQL Installation"
mysql  -e "
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%';
FLUSH PRIVILEGES;
"

echo "
[client]
user=root
password=$mysqlRootPassword
"   > /home/ec/.my.cnf

echo "Installing mytop"
yum -y install mytop
echo "
user=root
pass=$mysqlRootPassword
host=localhost
db=information_schema
delay=5
port=3306
batchmode=0
header=1
color=1
idle=1
" > ~/.mytop


chown ec:ec /home/ec/.my.cnf
chmod 600 /home/ec/.my.cnf
echo "Done"


chmod 600 ~/.mytop
echo "
user=root
pass=$mysqlRootPassword
host=localhost
db=information_schema
delay=5
port=3306
batchmode=0
header=1
color=1
idle=1
" > /home/ec/.mytop
chown ec:ec /home/ec/.mytop
chmod 600 /home/ec/.mytop


echo "
----------------
$(hostname) $0 completed
----------------
"