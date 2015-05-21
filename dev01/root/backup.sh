#!/bin/bash

##gitlab backup:

#this line was here before than was relinking directory backups for gitlab:
#
#root@dev01:~# ll /home/git/gitlab/tmp/backups
#lrwxrwxrwx 1 root root 17 May  6 17:51 /home/git/gitlab/tmp/backups -> /fs/backup/gitlab
#

# if file older more 3 day, then rename it
export GEM_HOME=/home/git/gitlab/vendor/bundle/ruby/2.1.0
export GEM_PATH=/home/git/gitlab/vendor/bundle/ruby/2.1.0
export NODE_PATH=/opt/node
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games:$GEM_HOME/bin:$NODE_PATH/bin
BACKUP_GITLAB_PATH="/fs/backup/gitlab";
cd $BACKUP_GITLAB_PATH
for i in $(find ./ -name "gitlab_backup_[0-9][0-9]*.tar" | sed "s/\.\///g"); do
        if test $(find $BACKUP_PATH -name $i -mtime +1); then mv "$i" "$i-old"; fi
done
# delete old files
if [ "$(echo $?)" == "0" ]; then
        rm -f $BACKUP_GITLAB_PATH/gitlab_backup*.tar-old
fi
# creating gitlab tar-archive
cd /home/git/gitlab
#env | grep -i ruby
#which node
#which bundle
#which gem
#gem search -l execjs
#echo "================================"
sudo -u git bundle exec rake gitlab:backup:create RAILS_ENV=production && mv $BACKUP_GITLAB_PATH/*gitlab_backup.tar  $BACKUP_GITLAB_PATH/gitlab_backup_`date +%d-%b-%y_%H-%M-%S`.tar

##redmine database backup:
#cd /home/redmine
#mysqldump redmine | gzip > /fs/backup/redmine_mysqldump_`date +%d-%b-%y_%H-%M-%S`.gz

#backuping SVN
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
