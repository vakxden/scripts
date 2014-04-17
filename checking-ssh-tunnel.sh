#!/bin/bash

###
### SSH Through or Over Proxy
###

### For ssh-connection from working PC to a home PC, through the corporate proxy server, used corkscrew.

### Only ssh-connecting command: $(ssh vakxden@vakxden.crabdance.com -o "ProxyCommand /usr/bin/corkscrew 127.0.0.1 3128 vakxden.crabdance.com 443")
### Only create ssh-tunnel command: $(ssh -f -N -R 2048:localhost:22 vakxden@vakxden.crabdance.com -o "ProxyCommand /usr/bin/corkscrew 127.0.0.1 3128 vakxden.crabdance.com 443")
### Retraction from home via ssh-tunnel: $(ssh -p 2048 dvac@127.0.0.1)

TAG=$(basename $0)
function l {
	/usr/bin/logger -t $TAG "$1"
}

ps aux | grep "ssh -f -N -R.*vakxden.crabdance.com" | grep -v grep
# if connection not found then previous command return value "1", start it
if [ $? -eq 1 ]
then
	l "Process with ssh-tunnelling 'ssh -f -N -R.*vakxden.crabdance.com' not found. Starting process..."
	ssh -f -N -R 2048:localhost:22 vakxden@vakxden.crabdance.com -o "ProxyCommand /usr/bin/corkscrew 127.0.0.1 3128 vakxden.crabdance.com 443" && l "Starting successfully!"
else
        l "Process 'ssh -f -N -R.*vakxden.crabdance.com' is already running"
	exit 0
fi

# for crontab
#
# m h  dom mon dow   command
#*/5 * * * * ~/git/scripts/checking-ssh-tunnel.sh >/dev/null 2>&1
