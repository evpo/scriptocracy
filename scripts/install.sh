#!/bin/bash

for scr in *
do
    if echo "$scr" | grep -E -e '^(install\.sh|.*\.txt)$' > /dev/null
    then
        continue
    fi
    cp -f -s $PWD/$scr $HOME/bin/
done
