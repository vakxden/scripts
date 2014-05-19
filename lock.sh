lockfile=/var/tmp/mylock
while true; do
	if ( set -o noclobber; echo "$$" > "$lockfile") 2> /dev/null; then

        	trap 'rm -f "$lockfile"; exit $?' INT TERM EXIT
		
		# body of script
        	ping vakxden.crabdance.com
	
        	# clean up after yourself, and release your trap
        	rm -f "$lockfile"
        	trap - INT TERM EXIT
	else
        	echo "Lock Exists: $lockfile owned by $(cat $lockfile)"
		sleep 2
	fi
done
