#!/bin/bash

# kill gpg-agent
result=$(ps -u jenkins | grep gpg-agent)
if [ $? -eq 0 ]; then 
  echo $result | awk '{print $1}' | xargs echo "would kill pid"
  result=$(ps -u jenkins | grep gpg-agent)
  if [ $? -eq 0 ]; then
    echo $result | awk '{print $1}' | xargs echo "would kill -9 pid"
  fi
else
  echo "no gpg-agent detected"
fi

# kill pinentry
result=$(ps -u jenkins | grep pinentry) 
if [ $? -eq 0 ]; then
  echo $result | awk '{print $1}' | xargs echo "would kill pid"
  result=$(ps -u jenkins | grep pinentry) 
  if [ $? -eq 0 ]; then
    echo $result | awk '{print $1}' | xargs echo "would kill -9 pid"
  fi
else
  echo "no pinentry detected"
fi

sudo chown jenkins:allstaff $(tty)

if [ "$PT_gpg2" == "true" ]; then
  echo 'would run eval $(gpg-agent --daemon --default-cache-ttl 2592000 --max-cache-ttl 2592000)'
else
  echo 'would run eval $(gpg-agent --use-standard-socket --daemon --default-cache-ttl 2592000 --max-cache-ttl 2592000 --write-env-file "/var/lib/jenkins/.gpg-agent-info")'
fi

directory="${PT_directory:-/var/lib/jenkins/enterprise-dist}"

if [ "$(realpath $directory)" != "$directory" ]; then
  echo "'directory' must be an absolute path with no '..'"
  exit 1
fi

if [ "$PT_use_rvm" == "true" ]; then
  rvm use system
fi

cd $directory
pwd
echo "my id is $(id)"
echo "would run rake prime_gpg"
exit $?
