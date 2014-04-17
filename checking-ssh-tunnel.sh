#!/bin/bash

###
### SSH Through or Over Proxy
###

### For ssh-connection from working PC to a home PC, through the corporate proxy server, used corkscrew.

### Only ssh-connecting command: $(ssh vakxden@vakxden.crabdance.com -o "ProxyCommand /usr/bin/corkscrew 127.0.0.1 3128 vakxden.crabdance.com 443")
### Only create ssh-tunnel command: $(ssh -f -N -R 2048:localhost:22 vakxden@vakxden.crabdance.com -o "ProxyCommand /usr/bin/corkscrew 127.0.0.1 3128 vakxden.crabdance.com 443")
### Retraction from home via ssh-tunnel: $(ssh -p 2048 dvac@127.0.0.1)

ps aux | grep "ssh -f -N -R.*vakxden.crabdance.com" | grep -v grep
# if connection not found then previous command return value "1", start it
if [ $? -eq 1 ]
then
        ssh -f -N -R 2048:localhost:22 vakxden@vakxden.crabdance.com
else
        echo "process 'ssh -f -N -R.*vakxden.crabdance.com' running"
	exit 0
fi
