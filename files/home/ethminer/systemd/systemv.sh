#!/bin/bash

case "$1" in 
start)
   /home/chiafarmer/systemd/run.sh &
   echo $!>/home/chiafarmer/chiafarmer.pid
   ;;
stop)
   kill `cat /home/chiafarmer/chiafarmer.pid`
   rm /home/chiafarmer/chiafarmer.pid
   ;;
restart)
   $0 stop
   $0 start
   ;;
status)
   if [ -e /home/chiafarmer/chiafarmer.pid ]; then
      echo chiafarmer is running, pid=`cat /home/chiafarmer/chiafarmer.pid`
      cd /home/chiafarmer/chia-blockchain
      . ./activate
      chia farm summary
   else
      echo chiafarmer is NOT running
      exit 1
   fi
   ;;
*)
   echo "Usage: $0 {start|stop|status|restart}"
esac

exit 0 
