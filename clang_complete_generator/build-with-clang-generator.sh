#!/bin/bash
function usage()
{
    cat <<EOM
$(basename $0) [--use-cmake] [--cmake-cmd <CMD>] [--make-cmd <CMD>] [--compiler-name <CMD>] [-o <OUT>] [--help]
EOM
}

script_dir="$( readlink ${BASH_SOURCE} )" || scriptdir="${BASH_SOURCE}"
script_dir="$( realpath ${script_dir} )"
script_dir="$( dirname -- $script_dir )"

use_cmake=0
cmake_command="cmake .."
make_command="make -i"
compiler_name="g++"
output_path="./compiler_options.txt"

options=$(getopt --longoptions "use-cmake,cmake-cmd:,make-cmd:,compiler-name:,help,h" "o:h" : "$@")
eval set -- $options
while true; do
    case "$1" in
        --use-cmake)
            use_cmake=1
            ;;
        --cmake-cmd)
            shift
            cmake_command="$1"
            use_cmake=1
            ;;
        --make-cmd)
            shift
            make_command="$1"
            ;;
        --compiler-name)
            shift
            compiler_name="$1"
            ;;
        -o)
            shift
            output_path="$1"
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        --)
            shift
            break
            ;;
    esac
    shift
done


echo $output_path
echo $cmake_command
echo "compiler_name=$compiler_name"
echo "output_path=$output_path"
echo "make_command=$make_command"
echo "use_cmake=$use_cmake"

proxy_name=$(basename $compiler_name)
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

export PATH=${tmp_dir}:$PATH
if [[ ${use_cmake} == 1 ]]; then
    eval $cmake_command
fi
eval $make_command

output_dir=$(dirname -- $output_path)
if [[ ! -r "${output_dir}/.ycm_extra_conf.py" ]]; then
    cp ${script_dir}/.ycm_extra_conf.py ${output_dir}/
fi
