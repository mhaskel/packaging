#!/bin/bash

function strip_quotes {
  local str=$1
  str="${str%\"}"
  str="${str#\"}"
  echo $str
}

params=$(</dev/stdin)

directory=$(strip_quotes $(echo "$params" | jq '.directory'))
if [ "$directory" == "null" ]; then
  directory=/var/lib/jenkins/enterprise-dist
fi

gpg2=$(strip_quotes $(echo "$params" | jq '.gpg2'))
if [ "$gpg2" == "null" ]; then
  gpg2=false
fi

use_rvm=$(strip_quotes $(echo "$params" | jq '.use_rvm'))
if [ "$use_rvm" == "null" ]; then
  use_rvm=false
fi

user=$(strip_quotes $(echo "$params" | jq '.user'))
if [ "$user" == "null" ]; then
  user=jenkins
fi

passphrase=$(strip_quotes $(echo "$params" | jq '.passphrase'))

if [ "$(realpath $directory)" != "$directory" ]; then
  echo '{ "_error": { "msg": "'directory' must be an absolute path with no '..'", "details": { "exit_code": "1" }}}'
  exit 1
fi

# kill gpg-agent
result=$(ps -u $user | grep gpg-agent)
if [ $? -eq 0 ]; then 
  echo $result | awk '{print $1}' | sudo xargs kill
  result=$(ps -u $user | grep gpg-agent)
  if [ $? -eq 0 ]; then
    echo $result | awk '{print $1}' | sudo xargs kill -9
  fi
else
  echo "no gpg-agent detected"
fi

# kill pinentry
result=$(ps -u $user | grep pinentry) 
if [ $? -eq 0 ]; then
  echo $result | awk '{print $1}' | sudo xargs kill
  result=$(ps -u $user | grep pinentry) 
  if [ $? -eq 0 ]; then
    echo $result | awk '{print $1}' | sudo xargs kill -9
  fi
else
  echo "no pinentry detected"
fi

sudo chown $user:allstaff $(tty)

if [ "$gpg2" == "true" ]; then
  eval $(gpg-agent --daemon --default-cache-ttl 2592000 --max-cache-ttl 2592000)
else
  eval $(gpg-agent --use-standard-socket --daemon --default-cache-ttl 2592000 --max-cache-ttl 2592000 --write-env-file "~${user}/.gpg-agent-info")
fi


if [ "$use_rvm" == "true" ]; then
  rvm use system
fi

cd $directory
echo "pwd == $(pwd)"
echo "my id is $(id)"
echo rake prime_gpg
exit $?
