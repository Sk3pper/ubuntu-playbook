#!/usr/bin/env bash

# fail fast: if there is an error do not proceed with the next line
set -Eeuo pipefail

# at the end of the script (normal or caused by an error or an external signal) the cleanup() function will be executed.
trap cleanup SIGINT SIGTERM ERR EXIT

# get script location
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

# printable function
usage() {
cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [-f] -p param_value arg1 [arg2...]

Script description here.

Available options:

-h, --help      Print this help and exit
-v, --verbose   Print script debug info
-f, --flag      Some flag description
-p, --param     Some param description
EOF
exit
}

# cleanup() can be called not only at the end but as well having the script done any part of the work. Not necessarily all the resources you try to cleanup will exist.
cleanup() {
    trap - SIGINT SIGTERM ERR EXIT
    # script cleanup here
}

# setup colors function
setup_colors() {
    if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
        NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
    else
        NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
    fi
}

# msg function
msg() {
    echo >&2 -e "${1-}"
}

# function to call
die() {
    local msg=$1
    local code=${2-1} # default exit status 1
    msg "$msg"
    exit "$code"
}

# parse all the params
parse_params() {
    # default values of variables set from params
    flag=0
    param=''

    while :; do

        # ${1-} uses to set a default value, in this case empty string. 
        # ${1-Default} in this case if ${1} is not set, "Dafault" string is set 
        case "${1-}" in
        -h | --help) usage ;;
        -v | --verbose) set -x ;;
        --no-color) NO_COLOR=1 ;;
        -f | --flag) flag=1 ;; # example flag
        -p | --param) # example named parameter
        param="${2-}" # take the second input parameter
        shift
        ;;

        # If the first argument starts with a dash followed by any other characters, it calls a function or command called die with an error message indicating that the option is unknown.
        -?*) die "Unknown option: $1" ;;

        *) break ;;
        esac
        # shifts the command-line arguments to the left to prepare for processing the next argument. This effectively removes the processed argument and its value from consideration.
        shift
    done

    # at the end the remaing information (after n*shift) will be the script arguments
    args=("$@")

    # check required params and arguments
    [[ -z "${param-}" ]] && die "Missing required parameter: param"
    [[ ${#args[@]} -eq 0 ]] && die "Missing script arguments"

    return 0
}

parse_params "$@"
setup_colors

# script logic here

msg "${RED}Read parameters:${NOFORMAT}"
msg "- flag: ${flag}"
msg "- param: ${param}"
msg "- arguments: ${args[*]-}"