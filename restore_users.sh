#!/usr/bin/env bash

users=( artem chiafarmer ethminer manager )

for i in "${users[@]}"
do
  useradd -m -G users,audio,video -s /bin/bash -d /home/$i $i
  chown -R $i:root /home/$i
  chmod -R a-x /home/$i
  chmod -R u=rwX /home/$i
  chmod -R go-rwx /home/$i
  chmod u+x /home/$i/bin/*.sh
  chmod u+x /home/$i/systemd/*.sh
done

usermod -a -G wheel manager


services=( chiafarmer ethminer )

for service in "${services[@]}"
do
  cp /home/$service/systemd/$service.service /etc/systemd/system/
  systemctl enable $service.service
done


chmod u+x /home/ethminer/NBMiner_Linux/nbminer || true