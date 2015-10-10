#!/bin/bash

#-# Command execution

execute() {
  print_info "$2"
  eval "$1"
  local status=$?
  print_result $status "$2"
  exit_if_command_failed $status
}

exit_if_command_failed() {
  ! [ $1 -eq 0 ] && exit 1
}


#-# File system

go_to() {
  cd "repositories/$1"
  [ $? -eq 0 ] && (print `pwd` && return 0) || return 1
}

get_absolute_file_path() {
  local filePath=`readlink -f $1`
  [ $? -eq 0 ] && (print $filePath && return 0) || return 1
}

get_location() {
  print "../../$1/$2"
}


#-# Git

is_git_repository() {
  git rev-parse
  return $?
}

git_pull() {
  git pull origin master
  return $?
}


#-# Maven

mvn_clean_install() {
  mvn clean install -DAPP_ENV -Dmaven.test.skip=true
  return $?
}


#-# JAR

get_artefact_path_in_target() {
  local results=(`find target -maxdepth 1 -iname *$1*.jar`)
  local filePath="${results[0]}"
  [ "$filePath" != "" ] && (print `get_absolute_file_path "$filePath"` && return 0) || return 1
}

get_resources_to_update() {
  local results=(`find $(get_location "resources" $1) -type f`)
  [ "${results}" != "" ] && (print $results && return 0) || return 1
}

get_resource_path_within_artefact() {
  local locationPath=`get_location "resources" "$1"`
  local artefactWithoutLocationPath="${2/$locationPath/''}"
  print "${artefactWithoutLocationPath:1}"
}

substitute_resources_within_artefact() {
  local artefactPath=`get_artefact_path_in_target $1`
  local resources=(`get_resources_to_update $1`)
  local resourcesDir=`get_location "resources" "$1"`
  local projectDir=`pwd`
  cd "${resourcesDir}"
  for i in ${!resources[*]}; do
    local resource=`get_resource_path_within_artefact $1 "${resources[$i]}"`
    jar uvf "${artefactPath}" "${resource}"
    ! [ $? -eq 0 ] && return 1
  done
  cd "${projectDir}"
  return 0
}

get_artefacts_in_artefact_folder() {
  local artefactFolder=`get_location 'artefacts' $1`
  print "`find $artefactFolder -iname *.jar`"
}

backup_previously_deployed_artefacts() {
  local artefacts=(`get_artefacts_in_artefact_folder $1`)
  for i in ${!artefacts[*]}; do
    mv -v ${artefacts[i]}{,-backup}
  done
}

copy_artefact_with_updated_resources() {
  local timestamp=`date "+%Y%m%d%H%M%S"`
  local artefactSourcePath=`get_artefact_path_in_target $1`
  local artefactFilename=`basename "${artefactSourcePath}"`
  local artefactDirectory=`get_location "artefacts" "$1"`
  local artefactDestinationPath="${artefactDirectory}/${artefactFilename%.jar}-${timestamp}.jar"
  cp -v "${artefactSourcePath}" "${artefactDestinationPath}"
}

execute_artefact() {
  local artefactFolder=`get_location 'artefacts' $1`
  cd "$artefactFolder"
  local artefacts=(`find -iname *.jar`)
  local artefact="${artefacts[0]}"
  [ "$artefact" == "" ] && return 1
  nohup java -jar $artefact &
  return 0
}


#-# Processes

kill_all_proceses_running_on_port() {
  sudo lsof -i ":${i}" | awk '{if (NR!=1) {print $2}}' | xargs sudo kill -9
  return $?
}


#-# Database

get_sql_scripts_in_resources_folder() {
  local resourcesFolder="src/main/resources/"
  print "`find ${resourcesFolder} -iname *.sql`"
}

execute_sql_scripts() {
  go_to $1 >& /dev/null
  local scripts=(`get_sql_scripts_in_resources_folder $1`)
  for i in ${!scripts[*]}; do
    local message="Execute ${scripts[i]}"
    ask_for_confirmation "$message"
    if answer_is_yes; then
      psql --echo-all --host=$2 --username=$3 --dbname=$4 --file=${scripts[i]}
      local status=$?
      print_result $status "$message"
      exit_if_command_failed $status
    fi
  done
}


#-# Display

ask() {
  print_question "$1"
  read reply
}

ask_for_confirmation() {
  print_question "$1 (y/n): "
  read reply
}

answer_is_yes() {
  [[ "$reply" =~ ^[Yy]$ ]] && return 0 || return 1
}

print() {
  printf "$1\n"
}

print_info() {
  printf "\e[0;35m[!] $1\e[0m\n"
}

print_question() {
  printf "\e[0;33m[?] $1\e[0m"
}

print_result() {
  [ $1 -eq 0 ] && print_success "$2" || print_error "$2"
}

print_success() {
  printf "\e[0;32m[✔] $1\e[0m\n\n"
}

print_error() {
  printf "\e[0;31m[x] $1\e[0m\n\n"
}


#-# Options

init() {
  local repoName=`basename $1`
  repoName="${repoName/'.git'/''}"

  if ! [ -d "repositories" ]; then
    mkdir -v repositories
  fi

  cd repositories

  git clone $1
  exit_if_command_failed $?

  if ! [ -d "../artefacts/${repoName}"  ]; then
    mkdir -pv "../artefacts/${repoName}"
  fi
  if ! [ -d "../resources/${repoName}" ]; then
    mkdir -pv "../resources/${repoName}"
  fi
}

build() {
  execute "go_to $1" "Navigate to $1"
  execute "is_git_repository" "Directory is git repository"
  execute "git_pull" "Pull changes from gitlab"
  execute "mvn_clean_install" "Build the project"
  execute "get_artefact_path_in_target $1" "Identify artefact in target"
  execute "substitute_resources_within_artefact $1" "Substitute resources within artefact"
}

database() {
  execute "execute_sql_scripts $1 $2 $3 $4" "Execute database scripts"
}

deploy() {
  build $1
  execute "kill_all_proceses_running_on_port $2" "Kill all processes running on port $2"
  execute "backup_previously_deployed_artefacts $1" "Backup previously deployed artefacts"
  execute "copy_artefact_with_updated_resources $1" "Copy the artefact with updated resources"
  database $1 $3 $4 $5
  execute "execute_artefact $1" "Start the application"
}

show_help() {
  print "Usage: deploy.sh <action> [args]"
  print "       init <git-repo-clone-url>"
  print "       Clone git project and setup directory structure"
  print ""
  print "       build <repo-name>"
  print "       Build the project from the lastest sources and update resources"
  print ""
  print "       database <repo-name> <db-host> <db-database> <db-user>"
  print "       Execute project database scripts"
  print ""
  print "       deploy <repo-name> <port> <db-host> <db-database> <db-user>"
  print "       Build the project from the latest sources, update resources, execute database scripts and run."
  exit 1
}


#-# Main

main() {
  case "$1" in
    init)
      ! [ $# -eq 2 ] && show_help
      init ${@:2}
      ;;
    build)
      ! [ $# -eq 2 ] && show_help
      build ${@:2}
      ;;
    database)
      ! [ $# -eq 5 ] && show_help
      database ${@:2}
      ;;
    deploy)
      ! [ $# -eq 6 ] && show_help
      deploy ${@:2}
      ;;
    *)
      show_help
  esac
}

main ${@}
