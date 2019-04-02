#!/bin/bash
if [[ "$1" == "--help" ]]; then
    echo "$0 [compiler_path] [output_path] [make_command]" >&2
    echo "compiler_path: example /usr/bin/g++" >&2
    echo "make_command: example make -j 4" >&2
    exit -1
fi

compiler_path=${1:-$(which g++)}
output_path=${2:-compiler_flags.txt}
make_command=${3:-make -j $(nproc)}

echo "compiler_path=$compiler_path"
echo "output_path=$output_path"
echo "make_command=$make_command"

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
flock -x $pipe_path echo "\$PWD \$@" >> $pipe_path
$compiler_path \$@
EOM
chmod 744 $tmp_dir/$proxy_name

rm -f $pipe_path
mkfifo $pipe_path
python3 $script_dir/receive-compiler.py $pipe_path $output_path &
receive_pid=$!
trap "finish" EXIT
PATH=${tmp_dir}:$PATH eval $make_command
