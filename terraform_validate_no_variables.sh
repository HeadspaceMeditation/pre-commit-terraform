#!/usr/bin/env bash
set -e

declare -a paths
index=0

for file_with_path in "$@"; do
  file_with_path="${file_with_path// /__REPLACED__SPACE__}"

  paths[index]=$(dirname "$file_with_path")
  let "index+=1"
done

for path_uniq in $(echo "${paths[*]}" | tr ' ' '\n' | sort -u); do
  path_uniq="${path_uniq//__REPLACED__SPACE__/ }"

  pushd "$path_uniq" > /dev/null
  >&2 echo "Running validate..."
  terraform validate -check-variables=false

  >&2 echo "Exit code: $?"

  if [[ "$?" -ne 0 ]]; then
    echo
    echo "Failed path: $path_uniq"
    echo "================================"
  fi
  
  popd > /dev/null
done
