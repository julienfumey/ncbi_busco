#! /usr/bin/sh

grep -v "alt-scaffold" $1 | cut -f7 | grep -v "^na$" | grep -v "#" | grep -v "RefSeq" | sed '/^[[:space:]]*$/d'