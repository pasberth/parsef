#!/usr/bin/env zsh
open=$1; shift
close=$1; shift
comb=$1; shift

accum=""
stack=()

while read L ; do
  if [[ $L = $open ]] ; then
    stack=("$accum" "$stack[@]")
    accum=""
  elif [[ $L = $close ]] ; then
    resul=$(echo "$accum" | $comb "$@")
    accum="$stack[1]$resul\n"
    shift stack
  else
    accum="$accum$L\n"
  fi
done

echo -n "$accum"