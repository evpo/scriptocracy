#!/bin/bash
if [[ $# != 2 ]]; then
    echo "$0 <compiler_path> <output_path>" >&2
    echo "compiler_path: example /usr/bin/g++" >&2
    exit -1
fi

compiler_path=$1
output_path=$2
proxy_name=$(basename $compiler_path)
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
tmp_dir=$(mktemp -d /tmp/compile_receiver.XXXXXXXX)
pipe_path=$tmp_dir/pipe

function finish()
{
    kill $receive_pid || true
    wait $receive_pid || true
    rm -rf $tmp_dir
}

cat >$tmp_dir/$proxy_name <<EOM
#!/bin/bash
echo "\$PWD \$@" >> $pipe_path
$compiler_path \$@
EOM
chmod 744 $tmp_dir/$proxy_name

rm -f $pipe_path
mkfifo $pipe_path
python3 $script_dir/receive-compiler.py $pipe_path $output_path &
receive_pid=$!
trap "finish" EXIT
PATH=${tmp_dir}:$PATH make -j1
