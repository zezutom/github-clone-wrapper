#!/bin/bash

function print_usage {
  echo "Usage: `basename $0` [-v] ssh_url"
}

function err {
  echo $1
  # TODO: print sample config
}

function parse_config {
  # ssh config
  file="/Users/tom/.ssh/config"

  # git users: lines starting with #username
  users=($(awk '{ if (index($0, "#") == 1) { print $2 }}' $file))
  user_count=${#users[*]}

  if [ ${#users[*]} == 0 ]; then
    err "You don't seem to have any user annotations"
    exit -1
  fi

  # ssh hosts: lines following the identified user lines
  host_lines=($(awk 'f{print;f=0} /#/{f=1}' $file))
  host_line_count=${#host_lines[*]}

  if [ $host_line_count -ne $(($user_count * 2)) ]; then
    err "Hosts don't match with users"
    exit -1
  fi 
  
  # extract host names 
  for (( i=1; i<=$(( $host_line_count - 1)); i+=2))
  do
    hosts=(${hosts[@]} ${host_lines[$i]})
  done
}

NO_ARGS=0
E_OPTERR=85
E_SYSERR=-1
verbose=false

if [ $# -eq $NO_ARGS ]; then
  print_usage
  exit $E_OPTERR
fi

while getopts ":h:v" option
do
  case $option in
    h) print_usage
       exit 0
       ;;
    v) echo "Enabling verbose mode"
       verbose=true
       ;;
    *) print_usage
       exit $E_OPTERR
       ;;
  esac
done

repo_url=$1

if [ -z ${repo_url+x} ]; then
  print_usage
  exit E_SYSERR
fi

# validate the repo url
repo_regex="git@(.+):(.+)\/.+\.git"
if [[ ! $repo_url =~ $repo_regex ]]; then
  err "$repo_url doesn't seem to be a valid repository"
  exit $E_SYSERR
fi

# ssh config
config="$HOME/.ssh/config"
if [ ! -f ${config} ]; then
  err "Please create SSH config as: ${config}"
  exit $E_SYSERR
fi

# a matrix of users and the associated hosts
declare -a users
declare -a hosts

# Identify users and hosts
parse_config

if [ "$verbose" = true ]; then
  # print config
  echo "Found mappings (user: host)"
  users_count=${#users[*]}
  for (( i=0; i<=$(( $users_count - 1)); i++))
  do
    echo "  ${users[$i]}: ${hosts[$i]}"
  done
fi

# find the corresponding ssh user
git_user="${BASH_REMATCH[2]}"
index=-1
for (( i=0; i<${#users[*]}; i++))
do
  if [[ "$git_user" = "${users[$i]}" ]]; then
    index=$i
    break
  fi
done

if [[ $index -lt 0 ]]; then
  err "No such user found in ssh config: ${git_user}"
  exit $E_SYSERR
fi

# replace the host
repo_url="${repo_url/${BASH_REMATCH[1]}/${hosts[$i]}}"
if [ "$verbose" = true ]; then
  echo "Updated repo url: $repo_url" 
fi

# clone the repo
git clone "$repo_url"
