#!/bin/bash

for scr in *
do
    if echo "$scr" | grep -E -e '^(install\.sh|.ycm_extra_conf\.py|.*\.txt)$' > /dev/null
    then
        continue
    fi
    cp -f -s $PWD/$scr $HOME/bin/
done

mkdir -p $HOME/.ycm
if [[ ! -r $HOME/.ycm/system_flags.txt ]]; then
    cp system_flags.txt $HOME/.ycm/
fi
