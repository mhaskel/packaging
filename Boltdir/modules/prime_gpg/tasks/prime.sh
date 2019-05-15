#!/bin/bash

function strip_quotes {
  local str=$1
  str="${str%\"}"
  str="${str#\"}"
  echo $str
}

params=$(</dev/stdin)
echo $params
echo ""

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

if [ "$(realpath $directory)" != "$directory" ]; then
  echo "'directory' must be an absolute path with no '..'"
  exit 1
fi

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

if [ "$gpg2" == "true" ]; then
  echo 'would run eval $(gpg-agent --daemon --default-cache-ttl 2592000 --max-cache-ttl 2592000)'
else
  echo 'would run eval $(gpg-agent --use-standard-socket --daemon --default-cache-ttl 2592000 --max-cache-ttl 2592000 --write-env-file "/var/lib/jenkins/.gpg-agent-info")'
fi


if [ "$use_rvm" == "true" ]; then
  echo "would run rvm use system"
fi

cd $directory
echo "pwd == $(pwd)"
echo "my id is $(id)"
echo "would run rake prime_gpg"
exit $?
