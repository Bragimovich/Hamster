#!/usr/bin/env bash

hamster_ruby="#!/usr/bin/env bash

cd \$(cat \${HOME}/.config/hamster/local.path) && bundle exec ruby hamster.rb $@"

hamster_bash="#!/usr/bin/env bash

help=\"
Usage: hamster COMMAND [ARGUMENT]…

COMMANDS LIST:
    build [PROJECT_NUMBER]          builds the main Hamster docker image or
                                    the pointed project's image
    grab PROJECT_NUMBER [ARGUMENT]… runs the pointed project in docker container with
                                    passed arguments
    dig PROJECT_NUMBER              makes initial directory and file structure for
                                    the pointed project
    do TASK_NAME [ARGUMENT]…        runs a task from the unexpected_tasks directory with
                                    passed arguments
    docker                          runs the Hamster docker container and puts you into

    telegram                        runs the Hamster's Telegram bot to hear messeages

    help                            prints this help
\"

if [ -z \"\$1\" ] ; then
  echo -ne \"\\033[31mError: It necessary to put the command and needed parameters after that!\\033[0m\\n\" >&2
  echo \"\$help\"

  exit 1
fi

action=\$1

shift

if [ \$action == 'help' ] ; then
  echo \"\$help\"
else
  bash \$(cat \${HOME}/.config/hamster/local.path)bin/\${action} \$@
fi

exit 0
"

function make_common_part() {
  bin_dir=$HOME/.local/bin/
  config_dir=$HOME/.config/hamster

  mkdir -p $bin_dir
  mkdir -p $config_dir
  echo "$(pwd)/" > $config_dir/local.path

  if [ $HOME != '/home/hamster' ] && [ -d /home/hamster/HarvestStorehouse ] ; then
    ln -sf /home/hamster/HarvestStorehouse $HOME/HarvestStorehouse
  else
    mkdir -p $HOME/HarvestStorehouse
  fi

  mkdir -p $HOME/ini/Hamster
  touch $HOME/ini/Hamster/config.yml
}

function make_ruby() {
  bundle config set path 'vendor/bundle'
  bundle install

  echo "$hamster_ruby" > hamster

  chmod +x hamster

  ln -sf $(pwd)/hamster ${bin_dir}hamster
}

function make_docker() {
  echo "$hamster_bash" > hamster

  chmod +x hamster
  ln -sf $(pwd)/hamster ${bin_dir}hamster

  ./hamster build
}

function ending() {
  case $SHELL in
    /bin/zsh)
      rc_file="$HOME/.zshrc"
      ;;
    /bin/bash)
      rc_file="$HOME/.bashrc"
  esac

  commentary="# set PATH so it includes user's privaite bin if it exists"
  path_addition="
$commentary
if [ -d \$HOME/.local/bin ] ; then
  export PATH=\$PATH:\$HOME/.local/bin
fi
"
  grep -q "$commentary" $rc_file || echo "$path_addition" >> $rc_file
  grep -q "$commentary" $HOME/.profile || echo "$path_addition" >> $HOME/.profile

  echo -ne "\033[33m"
  source $rc_file && source $HOME/.profile
  echo -ne "\033[0m"
}

function final() {
  echo
  echo "Hamster's installation complited."
  echo "You could put 'hamster help' to learn what you can do with Hamster"

  exit 0
}

if [ -z "$1" ] ; then
  echo "Please choose the variant of installation. If you choose 'Ruby',"
  echo "please, ensure that your version of Ruby is $(cat .ruby-version)."
  echo "If you choose 'Docker', please ensure that have installed Docker and"
  echo "your version of Docker is 20.10 or upper."

  PS3='Enter a number: '

  select number in Docker Ruby Exit ; do
    case $number in
      Docker)
        make_common_part && make_docker && ending && final
        break
        ;;
      Ruby)
        make_common_part && make_ruby && ending && final
        break
        ;;
      *)
        exit 0
        break
        ;;
    esac
  done

  exit 1
fi

if [ -n "$1" ] && [[ $1 == ruby ]] ; then
  make_common_part && make_ruby && ending && final
fi

if [ -n "$1" ] && [[ $1 == docker ]] ; then
  make_common_part && make_docker && ending && final
fi

exit 0

