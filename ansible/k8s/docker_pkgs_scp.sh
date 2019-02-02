#!/bin/bash
for node in kube-{master,node1,node2,normal}
do
  scp -r /root/docker/docker_pkgs $node:~ 
  scp init.sh $node:~
  [ $? -eq 0 ] && echo -e "$node docker pkgs \033[32;1mscped\033[0m" || exit
done &
