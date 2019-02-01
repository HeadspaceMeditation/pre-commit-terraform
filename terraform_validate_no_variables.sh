#!/usr/bin/env bash
set -e

declare -a paths
index=0

>&2 echo "Starting..."
>&2 echo "$@"

for file_with_path in "$@"; do
  file_with_path="${file_with_path// /__REPLACED__SPACE__}"

  paths[index]=$(dirname "$file_with_path")
  let "index+=1"
done

for path_uniq in $(echo "${paths[*]}" | tr ' ' '\n' | sort -u); do
  path_uniq="${path_uniq//__REPLACED__SPACE__/ }"

  pushd "$path_uniq" > /dev/null

  set +e
  terraform validate -check-variables=false

  if [[ "$?" -ne 0 ]]; then
    >&2 echo
    >&2 echo "Failed path: $path_uniq"
    >&2 echo "================================"
    exit 1
  fi
  
  set -e
  popd > /dev/null
done
