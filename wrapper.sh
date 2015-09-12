#!/bin/bash

# a matrix of users and the associated hosts
declare -a users 
declare -a hosts 

function parse_config {
  # ssh config
  file="/Users/tom/.ssh/config"

  # git users: lines starting with #username
  users=($(awk '{ if (index($0, "#") == 1) { print $2 }}' $file))

  # ssh hosts: lines following the identified user lines
  host_lines=($(awk 'f{print;f=0} /#/{f=1}' $file))
  
  # extract host names 
  host_line_count=${#host_lines[*]}
  for (( i=1; i<=$(( $host_line_count - 1)); i+=2))
  do
    hosts=(${hosts[@]} ${host_lines[$i]})
  done
}

parse_config

# print config
users_count=${#users[*]}
for (( i=0; i<=$(( $users_count - 1)); i++))
do
  echo "${users[$i]}: ${hosts[$i]}"
done
