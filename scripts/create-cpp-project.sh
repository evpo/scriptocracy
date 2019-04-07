#!/bin/bash
set -e
version=master

if [[ "$1" == "--help" ]]; then
    echo "$0 [project_path]" >&2
    exit -1
fi

project_path=${1:-cpp_project}
if [[ -d "$project_path" ]]; then
    echo "the directory $project_path exists" >&2
    exit -1
fi

tmp_dir=$(mktemp -d /tmp/cpp-project-template.XXXXXXXX)
trap "rm -rf $tmp_dir" EXIT
#-C $tmp_dir
wget -O - https://github.com/evpo/cpp-project-template/archive/${version}.tar.gz | tar xzvf - -C "$tmp_dir"
mv $tmp_dir/cpp-project-template-${version} "$project_path"
cd "$project_path"
git init .
git add -A
git commit -m "initial commit"
