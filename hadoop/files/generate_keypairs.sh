#!/bin/bash

names=${1:-"hdfs mapred yarn"}

for name in $names
do
  keyname=rsa-${name}
  if [ ! -f $keyname ]
  then
    echo "===> generating new keypair for user $name"
    ssh-keygen -q -t rsa -C ${name} -f $keyname -N '' 2>/dev/null
    ls -1 ${keyname} ${keyname}.pub
  else
    echo "===> skipping existing keypair for user $name"
  fi
done
