#!/usr/bin/env bash

import() {
  local starting_dir="$(pwd)"

  package_tree="/tmp/req_$$.tree"
  [ ! -f "$package_tree" ] && touch "$package_tree"

  package_map="/tmp/req_$$.map"
  if [ ! -f "$package_map" ]; then
    echo "#!/usr/bin/env bash" >> "$package_map"
    echo "package_tree=\"$package_tree\"" >> "$package_map"
  fi

  case "$1" in
    "./"*)
      package="${1#.\/}"
      package_path="$(dirname "$(follow_symlink "${BASH_SOURCE[1]}")")"

      if [ -f "${package_path}/${package}.sh" ]; then
        package_main="${package_path}/${package}.sh"
      elif [ -d "${package_path}/${package}" ]; then
        package_main="${package_path}/${package}/index.sh"
      else
        printf "\e[0;96mcoral\e[0m \e[0;31mERR!\e[0m \e[0;35mrequire \"$1\"\e[0m Can't find package \e[1;33m$package\e[0m! Does \e[1;33m${package_path}/${package}.sh\e[0m exist?\n"
        exit
      fi
      ;;
  esac

  echo "$package() {" >> "$package_map"
  echo ". /Users/qw3rtman/Documents/github/CoralSH/import/lib/import.sh" >> "$package_map"
  echo "import_function \"$package_main\" \"\$1\" \"$package\" && $package.\$1 \"\${@:2}\"" >> "$package_map"
  echo "}" >> "$package_map"
  echo "echo \"$package\" >> \"\$package_tree\"" >> "$package_map"

  . "$package_map"

  cd "$starting_dir"
}

import_function() {
  local starting_dir="$(pwd)"

  grep -qFx "$3" "$package_tree" || echo "$3" >> "$package_tree"
  grep -qFx "$3.$2" "$package_tree" || echo "$3.$2" >> "$package_tree"

  . $1

  functions=$(compgen -A function)
  for function in $functions; do
    case $function in
      $2) function_body=$(declare -f $function)
          new_function="${3}.${function}"
          eval "${function_body/$function/$new_function}"
          unset -f $function
          ;;

      *) grep -qFx "$function" "$package_tree" || unset -f "$function" ;;
    esac
  done

  cd "$starting_dir"
}

follow_symlink() {
  case $(uname -s) in
    Darwin) output=$(readlink "$1") ;;
    *) output=$(readlink -f "$1") ;;
  esac

  [ -z "$output" ] && output="$1"
  printf "%s" "$output"
}
