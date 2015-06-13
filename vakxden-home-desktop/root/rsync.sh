#!/bin/bash
echo "" >> /tmp/sync.log
echo `date` >> /tmp/sync.log
echo "" >> /tmp/sync.log
rsync -lzuogthrv /home/vakxden/.Skype /home/vakxden/Dropbox/Skype-history 2>&1 >> /tmp/sync.log
