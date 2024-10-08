#!/bin/sh

set -eu

tmpfile=$(mktemp)
trap "rm -f $tmpfile" 0

eval "$1" > $tmpfile

N=$(wc -l $tmpfile | awk '{print $1}')
n=0

while [ $n -lt $N ]; do
  n=$(( n + 1 ))
  line="$(awk "NR==$n" $tmpfile)"
  case "$line" in
    '#'*)  continue ;;
    '')    continue ;;
  esac
  echo "# Next: $line"
  read -p "# Run? [Y/n/q]: " answer
  case "$answer" in
    q*|Q*)
      echo "** Quit."
      break ;;
    y*|Y*|'')
      command=$(echo "$line" | sed 's/\t#.*//')
      echo "\$ $command"
      if ! eval "$command"; then
        read -p "# Command failed. Continue? [y/n]: " answer
        while true; do
          case "$answer" in
            y*|Y*)  break ;;
            n*|N*)  echo "** Quit."; exit ;;
            *)      echo "# Please Answer 'y' or 'n'. Continue? [y/n]" ;;
          esac
        done
      fi
      echo ;;
    *)
      echo ;;
  esac
done
