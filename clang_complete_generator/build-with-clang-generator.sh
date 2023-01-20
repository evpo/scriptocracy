#!/bin/bash
if [[ "$1" == "--help" ]]; then
    echo "$0 [compiler_name] [output_path] [make_command]" >&2
    echo "compiler_name: example g++" >&2
    echo "make_command: example make -j 4" >&2
    exit -1
fi

compiler_name=${1:-g++}
output_path=${2:-compiler_options.txt}
make_command=${3:-make}

echo "compiler_name=$compiler_name"
echo "output_path=$output_path"
echo "make_command=$make_command"

proxy_name=$(basename $compiler_name)
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
export PATH="\${PATH#*:}"
$compiler_name \$@
EOM
chmod 744 $tmp_dir/$proxy_name

rm -f $pipe_path
mkfifo $pipe_path
python3 $script_dir/receive-compiler.py $pipe_path $output_path &
receive_pid=$!
trap "finish" EXIT
PATH=${tmp_dir}:$PATH eval $make_command
