#ssh dvac@devzone.dp.ua "rm -rf /home/dvac/apache2/var/www/portal/*"
#scp -r $WORKSPACE/* dvac@devzone.dp.ua:/home/dvac/apache2/var/www/portal/
time rsync -rzv --delete --exclude "build.version.json" --exclude ".git" -e "ssh" $WORKSPACE/ dvac@devzone.dp.ua:/home/dvac/apache2/var/www/portal/
ssh dvac@devzone.dp.ua "/home/dvac/apache2/bin/apachectl restart"
