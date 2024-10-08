#!/usr/bin/env bash
set -e

declare -a paths
declare -a tfvars_files

TCI_VERSION="0.3.1"
if [[ $(terraform-config-inspect --version) != "$TCI_VERSION" ]]; then
  echo "Please install the latest version of terraform-config-inspect, by running:"
  echo "go install github.com/HeadspaceMeditation/terraform-config-inspect@${TCI_VERSION}"
  echo "Note: you may need to delete the $GOPATH/src/github.com/zclconf/go-cty directory because it changed from master -> main in GitHub."
  echo "For further help reach out to the ops team."
  exit 1
fi

index=0

for file_with_path in "$@"; do
  file_with_path="${file_with_path// /__REPLACED__SPACE__}"

  paths[index]=$(dirname "$file_with_path")

  if [[ "$file_with_path" == *".tfvars" ]]; then
    tfvars_files+=("$file_with_path")
  fi

  let "index+=1"
done

for path_uniq in $(echo "${paths[*]}" | tr ' ' '\n' | sort -u); do
  path_uniq="${path_uniq//__REPLACED__SPACE__/ }"

  README_PATH="$path_uniq"/README.md
  if [[ -f $README_PATH ]]; then
    if grep -q "BEGINNING OF TERRAFORM-DOCS HOOK" $README_PATH; then
      DOCS=$(terraform-config-inspect "$path_uniq")
      perl -i -s0pe 's/(<!-- BEGINNING OF TERRAFORM-DOCS HOOK -->).*(<!-- END OF TERRAFORM-DOCS HOOK -->)/\1\n$replacement\n\2/s' -- -replacement="$DOCS" "$README_PATH"
    else
      echo "<!-- BEGINNING OF TERRAFORM-DOCS HOOK -->" >> $README_PATH
      terraform-config-inspect "$path_uniq" >> $README_PATH
      echo "<!-- END OF TERRAFORM-DOCS HOOK -->" >> $README_PATH
      echo "Updating $README_PATH, please git add."
      exit 1
    fi
  else
    echo "<!-- BEGINNING OF TERRAFORM-DOCS HOOK -->" > $README_PATH
    terraform-config-inspect "$path_uniq" >> $README_PATH
    echo "<!-- END OF TERRAFORM-DOCS HOOK -->" >> $README_PATH
    echo "Creating $README_PATH, please git add."
    exit 1
  fi
done
