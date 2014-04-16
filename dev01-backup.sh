#!/bin/bash
##gitlab backup:
cd /home/git/gitlab
sudo -u git bundle exec rake gitlab:backup:create RAILS_ENV=production && mv /home/git/gitlab/tmp/backups/*gitlab_backup.tar  /fs/backup/gitlab_backup_`date +%d-%b-%y_%H-%M-%S`.tar
##redmine database backup:
cd /home/redmine
/usr/bin/mysqldump -uredmine -pPASSWD redmine | gzip > /fs/backup/redmine_mysqldump_`date +%d-%b-%y_%H-%M-%S`.gz
##backuping SVN
rsync -rtv /var/svn/ /fs/backup/svn/
#mysql
cd /fs/backup/mysql_dumps && rm -rf *.sql && for i in $(mysql -u root -pPASSWD -e "show databases" | awk '{print $1}'); do mysqldump -u root -pPASSWD $i > $i.sql /dev/null 2>&1; done
