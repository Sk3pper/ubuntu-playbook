# Ubuntu Playbook 🐧
Helpful playbook to install all the necessary components on fresh ubuntu installation. The purpose of this script is to easy install all the necessary tools/configurations in a kali machine. The supported installations/configurations in this moment are:
* vscode
* zsh, ohmyz and powerlevel10k
* pyenv and enable virtualenv version on zsh bash
* docker-ce, docker compose plugin
* minikube
* golang (v1.21.6 x86-64)
  
<!-- ## Table of contents
    * [General info](#general-info)
    * [Technologies](#technologies)
    * [Setup](#setup) 
-->

## Installation 🔨

```
wget -qO ubuntu-playbook.sh https://raw.githubusercontent.com/Sk3pper/ubuntu-playbook/main/Bash/ubuntu-playbook.sh
chmod 744 ./ubuntu-playbook.sh
./ubuntu-playbook.sh --help
```

<!-- Usage section -->
## Usage 🔫

### Bash 💻
#### Usage
```
ubuntu-playbook.sh [-h] [-v] [--all] [--vscode] [--zsh] [--user] [--pl10k] [--pyenv] [--docker] [--golang] -s stable-debian-version -u zsh-user --log-path-file log-playbook

Available options:
-h, --help                  Print this help and exit
-v, --verbose               Print script debug info
-l, --log-path-file         log path file (if not specified only default messages are printed on the terminal)  
-u, --user                  Specify the user to install components             
-a, --all                   Install all the tools listed above
-c, --vscode                Install vscode
-z, --omz                   Install zsh and oh-my-zsh
-k, --pl10k                 Install powerlevel10k template on zsh
-p, --pyenv                 Install pyenv
-d, --docker                Install docker-ce and docker-compose-plugin
-g, --golang                Install golang 1.21.6 x86-64
-m, --minikube              Install latest minikube version
```

#### Examples
```
# install all components
./ubuntu-playbook.sh --all --user ubuntu --log-path-file log

# install vscode
./ubuntu-playbook.sh --vscode --log-path-file log

# install oh-my-zsh and powerlevel10k
./ubuntu-playbook.sh --omz --pl10k --user ubuntu --log-path-file log

# install pyenv
./ubuntu-playbook.sh --pyenv --user ubuntu --log-path-file log

# install docker-ce, docker compose plugin
./ubuntu-playbook.sh --docker  --user ubuntu --log-path-file log

# install golang v1.21.6 x86-64
./ubuntu-playbook.sh --golang --log-path-file log

# install golang minikube
./ubuntu-playbook.sh --minikube --log-path-file log
```

<!-- Technologies section -->

## Technologies
<!-- I implemented it in three different ways: bash, python and golang. -->

### Bash 💻
Template bash script template is taken from [script-template.sh](https://gist.github.com/m-radzikowski/53e0b39e9a59a1518990e76c2bff8038). In this following [link](https://betterdev.blog/minimal-safe-bash-script-template/) you can find the full article. I added the source code template under /Bash folder with mine useful comments.

<!-- ### Python 🐍
#Todo

### Golang 🐹
#Todo -->

<!-- Enviroment where it was tested -->

## Tests
Tested on
- [x] ubuntu 22.04.1