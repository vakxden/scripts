#!/bin/bash

##gitlab backup:
cd /home/git/gitlab
#this line was here before than was relinking directory backups for gitlab:
#
#root@dev01:~# ll /home/git/gitlab/tmp/backups
#lrwxrwxrwx 1 root root 17 May  6 17:51 /home/git/gitlab/tmp/backups -> /fs/backup/gitlab
#
#sudo -u git bundle exec rake gitlab:backup:create RAILS_ENV=production && mv /home/git/gitlab/tmp/backups/*gitlab_backup.tar  /fs/backup/gitlab_backup_`date +%d-%b-%y_%H-%M-%S`.tar
mv /home/git/gitlab/tmp/backups/*gitlab_backup*.tar /home/git/gitlab/tmp/backups/gitlab_backup.tar_old
sudo -u git bundle exec rake gitlab:backup:create RAILS_ENV=production && mv /home/git/gitlab/tmp/backups/*gitlab_backup.tar  /home/git/gitlab/tmp/backups/gitlab_backup_`date +%d-%b-%y_%H-%M-%S`.tar
if [ "$(echo $?)" == "0" ]; then
        rm -f /home/git/gitlab/tmp/backups/gitlab_backup.tar_old
fi

##redmine database backup:
cd /home/redmine
mysqldump redmine | gzip > /fs/backup/redmine_mysqldump_`date +%d-%b-%y_%H-%M-%S`.gz

##backuping SVN
rsync -rtv /var/svn/ /fs/backup/svn/

#mysql ( password in /root/.my.cnf )
cd /fs/backup/mysql_dumps
for i in $(mysql -e "show databases" | awk '{print $1}' | egrep -v "information_schema|performance_schema|Database|accounts")
do
        mv $i.sql $i.sql_old && mysqldump $i > $i.sql #/dev/null 2>&1
        if [ "$(echo $?)" == "0" ]; then
                rm -f $i.sql_old
        fi
done
