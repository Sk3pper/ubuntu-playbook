#!/usr/bin/env bash

<<comment
The purpose of this script is to easy install all the necessary tools/configurations in a john machine. 
The supported installations/configurations in this moment are:
    vscode
    zsh, ohmyz and powerlevel10k
    pyenv and enable virtualenv version on zsh bash (if present)
    docker-ce, docker compose plugin
    golang 
    minikube
comment

# global variables
config_suffix_path="https://raw.githubusercontent.com/Sk3pper/ubuntu-playbook/main/bash/config"

# golang
golang_version="1.24.1"
platform="linux-amd64"
binary_release="go${golang_version}.${platform}.tar.gz"

# fail fast
set -Eeuo pipefail

# at the end of the script (normal or caused by an error or an external signal) the cleanup() function will be executed.
trap cleanup SIGINT SIGTERM ERR EXIT

# get script location
# script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

usage() {
msg "${NOFORMAT}"
cat << EOF # remove the space between << and EOF, this is due to web plugin issue
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [--all] [--vscode] [--zsh] [--user] [--pl10k] [--pyenv] [--docker] [--golang] -u zsh-user --log-path-file log-playbook

Available options:
-h, --help                  Print this help and exit
-v, --verbose               Print script debug info
-l, --log-path-file         log path file (if not specified only default messages are printed on the terminal)    
-u, --user                  Specify the user to install components           
-a, --all                   Install all the tools listed above
-c, --vscode                Install vscode [latest version]
-z, --omz                   Install zsh and oh-my-zsh [latest version]
-k, --pl10k                 Install powerlevel10k template on zsh [latest version]
-p, --pyenv                 Install pyenv [latest version]
-d, --docker                Install docker-ce and docker-compose-plugin [latest version]
-g, --golang                Install golang [$binary_release version]
-m, --minikube              Install latest minikube version [latest version]

Example:
    - ./ubuntu-playbook.sh --all --user john --log-path-file log
    - ./ubuntu-playbook.sh --vscode --log-path-file log
    - ./ubuntu-playbook.sh --omz --pl10k --user john --log-path-file log
    - ./ubuntu-playbook.sh --pyenv --user john --log-path-file log
    - ./ubuntu-playbook.sh --docker --user john --log-path-file log
    - ./ubuntu-playbook.sh --golang --user john --log-path-file log
    - ./ubuntu-playbook.sh --minikube --log-path-file log
EOF
exit
}

cleanup() {
    trap - SIGINT SIGTERM ERR EXIT
    # script cleanup here
}

setup_colors() {
    if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
        NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' GRAY="\033[0;37m"
    else
        NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' GRAY=''
    fi
}

msg() {
    # $1 -> color message
    # $2 -> message
    echo >&2 -e "${1}${2-}"

    # write out to log file if it specified
    if [ "$log_path_file" != "/dev/null" ]; then
        echo -e "${2-}" >> "$log_path_file"
    fi
}

die() {
    local msg=$1
    local code=${2-1} # default exit status 1
    msg "$NOFORMAT" "$msg"
    exit "$code"
}

parse_params() {
    # default values of variables set from params
    all=0
    vscode=0
    zsh=0
    pl10k=0
    pyenv=0
    docker=0
    golang=0
    minikube=0
    user=""
    log_path_file="/dev/null"

    while :; do
        case "${1-}" in
        # flags
        -h | --help) usage ;;
        -v | --verbose) set -x ;;
        --no-color) NO_COLOR=1 ;;
        -a | --all) all=1 ;; 
        -c | --vscode) vscode=1 ;;
        -z | --omz) zsh=1 ;;
        -k | --pl10k) pl10k=1 ;;
        -p | --pyenv) pyenv=1 ;;
        -g | --golang) golang=1;;
        -d | --docker) docker=1 ;;
        -m | --minikube) minikube=1 ;;

        # named parameters
        -u | --user) 
        user="${2-}"
        shift ;;
        -l | --log-path-file) 
        log_path_file="${2-}"
        shift ;;

        -?*) die "Unknown option: $1" ;;
        *) break ;;
        esac
        # shifts the command-line arguments to the left to prepare for processing the next argument. This effectively removes the processed argument and its value from consideration.
        shift
    done

    # at the end the remaining information (after n*shift) will be the script arguments
    args=("$@")

    # check required params and arguments
    # [[ -z "${param-}" ]] && die "Missing required parameter: param"
    # [[ ${#args[@]} -eq 0 ]] && die "Missing script arguments"

    return 0
}

has_sudo() {
    local prompt

    prompt=$(sudo -nv 2>&1)
    if [ $? -eq 0 ]; then
        echo "has_sudo__pass_set"
    elif echo "$prompt" | grep -q '^sudo:'; then
        echo "has_sudo__needs_pass"
    else
        echo "no_sudo"
    fi
}

notify_elevate () {
    local cmd=$@
    HAS_SUDO=$(has_sudo)

    case "$HAS_SUDO" in
        has_sudo__needs_pass)
            echo " Please supply sudo password for the following command: sudo $cmd"
            ;;
    esac
}

install_all(){
    msg "${GREEN}" "\n******** Installing all components ******"
    install_vscode
    install_zsh_omz
    install_pl10k
    install_pyenv
    install_docker
    install_golang
    install_minikube
    msg "${GREEN}" "****************************************************"
}

install_vscode(){
    msg "${GRAY}" "\n******** vscode ******"

    local cmd="apt -y install wget gpg"
    notify_elevate "$cmd"
    sudo $cmd &>> ${log_path_file}

    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg

    sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg &>> "${log_path_file}"
    sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list' &>> "${log_path_file}"
    rm -f packages.microsoft.gpg &>> "${log_path_file}"

    msg "${GRAY}" " Updating system...."
    sudo apt -y install apt-transport-https &>> "${log_path_file}"
    sudo apt update &>> "${log_path_file}"

    msg "${GRAY}" " Installing vscode...."
    sudo apt install code &>> "${log_path_file}" # or code-insiders

    msg "${GRAY}" "****************************************************"
}

install_zsh_omz(){
    msg "${BLUE}" "\n******** zsh and oh My Zsh! ******"
    # install ZSH
    local cmd="apt -y install zsh git curl"
    notify_elevate "$cmd"
    sudo $cmd &>> ${log_path_file}

    # install oh-my-zsh via curl
    msg "${BLUE}" " Installing oh My Zsh! ******"

    # --unattended: sets both CHSH and RUNZSH to 'no'
    # CHSH - 'no' means the installer will not change the default shell (default: yes) -> changed after
    # RUNZSH - 'no' means the installer will not run zsh after the install (default: yes)
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended &>> "${log_path_file}"

    msg "${BLUE}" " Installing zsh-autosuggestions"
    # install zsh-autosuggestions 
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions &>> "${log_path_file}"

    msg "${BLUE}" " Installing zsh-syntax-highlighting"

    # zsh-syntax-highlighting 
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting &>> "${log_path_file}"

    # switch from BASH to ZSH
    sudo chsh -s $(which zsh) "$user" 1>> "${log_path_file}"

    # check if $user has set properly
    local check
    check=$(sudo cat /etc/passwd | grep "$user")

    if [[ "$check" != *"/bin/zsh"* ]]; then
        die "switch from old to ZSH bash it didn't work out"
    fi

    msg "${BLUE}" " Enable zsh-autosuggestions and zsh-syntax-highlighting"
    # enable zsh-autosuggestions and zsh-syntax-highlighting
    sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' /home/"${user}"/.zshrc &>> "${log_path_file}"

    msg "${BLUE}" " Important: in order for the changes to take effect, you must log out and back in to enable the ZSH shell."
    msg "${BLUE}" "****************************************************"
}

install_pl10k(){
    # check if .oh-my-zsh is installed
    if [ ! -d "/home/${user}/.oh-my-zsh" ];
    then
        die "${RED} Install oh-my-zsh first (./ubuntu-playbook.sh --omz --user <username>)"
    fi

    msg "${CYAN}" "\n******** powerlevel10k ******"

    # download powerlevel10k theme
    if [ ! -d "/home/${user}/.oh-my-zsh/custom/themes/powerlevel10k" ];
    then
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k &>> "${log_path_file}"
    else
        msg "${CYAN}" "\n powerlevel10k theme is already present, enabling it"
    fi

    # enable powerlevel10k theme
    sed -i 's/ZSH_THEME="robbyrussell"/ ZSH_THEME="powerlevel10k\/powerlevel10k"/' /home/"${user}"/.zshrc &>> "${log_path_file}"

    # edit .zshrc file adding in the head of file
    local text_to_add
    text_to_add="# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.\n# Initialization code that may require console input (password prompts, [y/n]\n# confirmations, etc.) must go above this block; everything else may go below.\nif [[ -r \"\${XDG_CACHE_HOME:-\$HOME/.cache}/p10k-instant-prompt-\${(%):-%n}.zsh\" ]]; then\nsource \"\${XDG_CACHE_HOME:-\$HOME/.cache}/p10k-instant-prompt-\${(%):-%n}.zsh\"\nfi\n"
    local zshrc_payload
    zshrc_payload=$(cat "/home/${user}/.zshrc")
    echo -e "$text_to_add" > /home/"${user}"/.zshrc
    echo "$zshrc_payload" >> /home/"${user}"/.zshrc

    # edit .zshrc file adding in the tail
    echo -e "\n# To customize prompt, run \`p10k configure\` or edit ~/.p10k.zsh.\n[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >>  /home/"${user}"/.zshrc

    # download customize p10k.zsh config file under /home/"${user}"/.p10k.zsh path
    wget -O /home/"${user}"/.p10k.zsh ${config_suffix_path}/p10k.zsh &>> "${log_path_file}"
    wget -O /home/"${user}"/.cache/p10k-instant-prompt.zsh ${config_suffix_path}/p10k-instant-prompt.zsh &>> "${log_path_file}"
    chmod 700 /home/"${user}"/.cache/p10k-instant-prompt.zsh

    wget -O /home/"${user}"/.cache/p10k-instant-prompt.zsh.zwc ${config_suffix_path}/p10k-instant-prompt.zsh.zwc &>> "${log_path_file}"
    chmod 444 /home/"${user}"/.cache/p10k-instant-prompt.zsh.zwc

    msg "${CYAN}" " To customize prompt as you like, open new terminal and run \`p10k configure\` or edit ~/.p10k.zsh."

    msg "${CYAN}" "****************************************************"
}

install_pyenv(){
    msg "${PURPLE}" "\n******** pyenv ******"

    msg "${PURPLE}" " Updating system...."
    local cmd="apt update"
    notify_elevate "$cmd"
    sudo $cmd &>> ${log_path_file}\

    msg "${PURPLE}" " Installing dependencies...."
    cmd="apt install -y build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev python3-openssl git"
    notify_elevate "$cmd"
    sudo $cmd &>> ${log_path_file}

    # install pyenv
    msg "${PURPLE}" " Installing pyenv...."
    curl -fsSL https://raw.githubusercontent.com/pyenv/pyenv-installer/master/bin/pyenv-installer | bash &>> "${log_path_file}"

    # load pyenv automatically by appending to .zshrc
    # check if .zshrc is installed
    if [[ -f "/home/${user}/.zshrc" ]]; then
        msg "${PURPLE}" " Adding 'pyenv' to the load path of .zshrc ...."
        echo -e "\n# ======= pyenv load path config ======= \nexport PYENV_ROOT=\"\$HOME/.pyenv\" \nexport PATH=\"\$PYENV_ROOT/bin:\$PATH\" \nif command -v pyenv 1>/dev/null 2>&1; then \neval \"\$(pyenv init --path)\" \nfi \neval \"\$(pyenv virtualenv-init -)\"" >> /home/"${user}"/.zshrc
    else
        msg "${PURPLE}" " The following string should be manually added to your shell configuration file (such as.bashrc)"
        echo -e "\n# ======= pyenv load path config ======= \nexport PYENV_ROOT=\"\$HOME/.pyenv\" \nexport PATH=\"\$PYENV_ROOT/bin:\$PATH\" \nexport PATH=\"\$(pyenv root)/versions/\$(pyenv version-name)/bin:$PATH\" \nif command -v pyenv 1>/dev/null 2>&1; then \neval \"\$(pyenv init --path)\" \nfi \neval \"\$(pyenv virtualenv-init -)\""
    fi   

    msg "${PURPLE}" "****************************************************\n"
}

install_docker(){
    msg "${ORANGE}" "******** Installing docker ******"

    # uninstall all conflicting packages
    set +Eeuo pipefail
    local cmd="apt remove docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc"
    notify_elevate "$cmd"
    for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; 
        do 
            echo -e "\nsudo apt remove $pkg" &>> ${log_path_file}; 
            sudo apt remove $pkg &>> ${log_path_file}; 
        done
    set -Eeuo pipefail

    msg "${ORANGE}" " Updating system...."
    sudo apt update &>> "${log_path_file}"
    
    msg "${ORANGE}" " Set up Docker's apt repository....."
    sudo apt install ca-certificates curl &>> "${log_path_file}"
    sudo install -m 0755 -d /etc/apt/keyrings &>> "${log_path_file}"
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc &>> "${log_path_file}"
    sudo chmod a+r /etc/apt/keyrings/docker.asc &>> "${log_path_file}"

    # add the repository to apt sources:
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update &>> "${log_path_file}"

    msg "${ORANGE}" " Installing docker....."
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin &>> "${log_path_file}"

    # add your user to the 'docker' group
    sudo usermod -aG docker "$user" &>> "${log_path_file}"

    # check installation
    sudo docker pull hello-world &>> "${log_path_file}"
    local check
    check=$(sudo docker run hello-world | head -2)
    msg "${ORANGE}" " Check docker installation: $check"
    msg "${ORANGE}" "****************************************************\n"
}

install_golang(){
    url_suffix="https://golang.org/dl/"
    download_url="${url_suffix}${binary_release}"

    msg "${GRAY}" "******** Installing golang ******"

    # download golang
    msg "${GRAY}" " Downloading golang binary release at ${download_url}"
    wget -q $download_url &>> ${log_path_file}; 

    # remove any previous Go installation by deleting the /usr/local/go folder (if it exists), then extract the archive you just downloaded into /usr/local, creating a fresh Go tree in /usr/local/go
    # (You may need to run the command as root or through sudo).
    # do not untar the archive into an existing /usr/local/go tree. This is known to produce broken Go installations.
    msg "${GRAY}" " Remove any previous Go installation by deleting the /usr/local/go folder (if it exists)"
    local cmd="rm -rf /usr/local/go"
    notify_elevate "$cmd"
    sudo $cmd &>> ${log_path_file}; 

    msg "${GRAY}" " Extract the archive into /usr/local, creating a fresh Go tree in /usr/local/go"
    cmd="tar -C /usr/local -xzf ${binary_release}"
    notify_elevate "$cmd"
    sudo $cmd &>> ${log_path_file}; 

    # add /usr/local/go/bin to the PATH environment variable.
    # you can do this by adding the following line to your $HOME/.profile or /etc/profile (for a system-wide installation):
    export PATH=$PATH:/usr/local/go/bin
     
    # load pyenv automatically by appending to .zshrc
    # check if .zshrc is installed
    if [[ -f "/home/${user}/.zshrc" ]]; then
        msg "${GRAY}" " Adding 'golang' to the load path .zshrc ...."
        echo -e "\n# ======= golang load path config =======\nexport PATH=\$PATH:/usr/local/go/bin" >> /home/"${user}"/.zshrc
    else
        msg "${PURPLE}" " The following string should be manually added to your shell configuration file (such as.bashrc)"
        echo -e "\n# ======= golang load path config =======\nexport PATH=\$PATH:/usr/local/go/bin"
    fi   

    # verify that you've installed Go by opening a command prompt and typing the following command
    export PATH=$PATH:/usr/local/go/bin
    local check
    check=$(go version)
    msg "${GRAY}" " Check go installation: $check"

    msg "${GRAY}" " Cleaning file $binary_release"
    rm $binary_release

    # confirm that the command prints the installed version of Go.
    msg "${GRAY}" "****************************************************\n"
}

install_minikube(){
    msg "${BLUE}" "******** Installing minikube ******"
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 &>> ${log_path_file}; 

    local cmd="install minikube-linux-amd64 /usr/local/bin/minikube"
    notify_elevate "$cmd"
    sudo $cmd &>> ${log_path_file}; 

    msg "${BLUE}" "****************************************************\n"
}

# start script
setup_colors
parse_params "$@"

# fail if all and the other flags are set
if [ $all -eq 1 ] && { [ $vscode -eq 1 ] || [ $zsh -eq 1 ] || [ $pl10k -eq 1 ] || [ $pyenv -eq 1 ] || [ $docker -eq 1 ] || [ $golang -eq 1 ] || [ $minikube -eq 1 ]; };
then
    msg "${RED}" "It is not possible to proceed. Specify to install all OR specifics components (1)"
    usage
fi

# fail if all and the other flags are not set
if [ $all -eq 0 ] && { [ $vscode -eq 0 ] && [ $zsh -eq 0 ] && [ $pl10k -eq 0 ] && [ $pyenv -eq 0 ] && [ $docker -eq 0 ] && [ $golang -eq 0 ] && [ $minikube -eq 0 ]; };
then
    msg "${RED}" "It is not possible to proceed. Specify to install all OR specifics components (2)"
    usage
fi

# ==== all ====
if [ $all -eq 1 ]  &&  { [ -z "$user" ]; } ;
then
    msg "${RED}" "It is not possible to proceed. Specify the user to enable components (eg: john)"
    usage
elif [ $all -eq 1 ] &&  { [ ! -z "$user" ]; } ;
then
    install_all
    cleanup
fi

# === vscode ====
if [ $vscode -eq 1 ];
then
    install_vscode
fi

# === zsh, oh-my-zsh, powerlevel10k  ===
if [ $zsh -eq 1 ] && [ -z "$user" ] ;
then
    msg "${RED}" "It is not possible to proceed. Specify the user to enable zsh (eg: john)"
    usage
elif [ $zsh -eq 1 ] &&  [ ! -z "$user" ] ;
then
    install_zsh_omz
fi

if [ $pl10k -eq 1 ] && [ -z "$user" ] ;
then
    msg "${RED}It is not possible to proceed. Specify the user to install powerlevel10k template (eg: john)"
    usage
elif [ $pl10k -eq 1 ] &&  [ ! -z "$user" ] ;
then
    install_pl10k
fi

# === pyenv ===
if [ $pyenv -eq 1 ] && [ -z "$user" ] ;
then
    msg "${RED}" "It is not possible to proceed. Specify the user to enable pyenv automatically in the user terminal (eg: john)"
    usage
elif [ $pyenv -eq 1 ] &&  [ ! -z "$user" ] ;
then
    install_pyenv
fi

# === docker ===
if [ $docker -eq 1 ] &&  { [ -z "$user" ]; } ;
then
    msg "${RED}" "It is not possible to proceed. Specify
    - stable debian version used in this moment (eg: bookworm)
    - the user to enable components (eg: john)"
    usage
elif [ $docker -eq 1 ] &&  { [ ! -z "$user" ]; } ;
then
    install_docker
fi

# === golang ===
if [ $golang -eq 1 ] && [ -z "$user" ] ;
then
    msg "${RED}" "It is not possible to proceed. Specify the user to enable golang automatically in the user terminal (eg: john)"
    usage
elif [ $golang -eq 1 ] &&  [ ! -z "$user" ] ;
then
    install_golang
fi

# === minikube ===
if [ $minikube -eq 1 ] ;
then
    install_minikube
fi


cleanup