#!/usr/bin/env zsh
open=$1; shift
close=$1; shift

accum=""
stack=()

while read L ; do
  if [[ $#stack != 0 ]] && [[ $L = $close ]] ; then
    resul=$(echo -n "$accum" | "$@")
    accum="$stack[1]$resul\n"
    shift stack
  elif [[ $L = $open ]] ; then
    stack=("$accum" "$stack[@]")
    accum=""
  elif [[ $L = $close ]] ; then
    echo "$(basename $0) '$open' '$close'" "$@"": \`$close' unexpected" >&2
    exit 1
  else
    accum="$accum$L\n"
  fi
done

if [[ $#stack != 0 ]] ; then
  echo "$(basename $0) '$open' '$close'" "$@"": \`$close' expected" >&2
  exit 1
else
  echo -n "$accum"
fi