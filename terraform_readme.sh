#!/usr/bin/env bash
set -e

declare -a paths
declare -a tfvars_files

if [[ $(terraform-config-inspect --version) != "0.2.0" ]]; then
  echo "Please install the latest version of terraform-config-inspect, by running:"
  echo "go get -u github.com/HeadspaceMeditation/terraform-config-inspect"
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
