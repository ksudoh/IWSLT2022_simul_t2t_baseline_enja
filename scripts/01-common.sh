###
### Common subroutines for IWSLT 2022
###   English-to-Japanese Simultaneous text-to-text baselines
###

##
## Common subroutines
##

#
# Messages
#
notice () {
    echo "Notice ($0):" "$@" 1>&2
    return 0
}

warn () {
    echo "Warning ($0):" "$@" 1>&2
    return 0
}

error () {
    echo "Error ($0):" "$@" 1>&2
    return 1
}

error_and_die () {
    error "$@"
    exit 1
}

#
# getopt
#
parse_options () {
    verbose=0
    while getopts 'v' opt ; do
        case "${opt}" in
            "v")
                verbose=1
                ;;
            *)
                ;;
        esac
    done
    return $((OPTIND - 1))
}

#
# Check
#
check_env () {
    for envvar in $* ; do
        if test -z "${!envvar}" ; then
            error_and_die "Environment variable ${envvar} is not set."
        fi
    done
    return 0
}

check_executable () {
    for exe in $* ; do
        if test ! -x ${exe} ; then
            error_and_die "${exe} is not executable."
        fi
    done
    return 0
}

check_dir () {
    for dir in $* ; do
        if test ! -d ${dir} ; then
            error_and_die "Directory ${dir} is not found."
        fi
    done
    return 0
}

check_file () {
    for file in $* ; do
        if test ! -s ${file} ; then
            error_and_die "File ${file} is empty or not found."
        fi
    done
    return 0
}

#
# Other common subroutines
#
make_dir () {
    local dir=$1
    if test ! -d ${dir} ; then
        mkdir -p ${dir}
        if test $? -ne 0 ; then
            error_and_die "Cannot create directory ${dir}."
        fi
    fi

    return 0
}

copy_file () {
    local file_src=$1
    local file_dst=$2

    if ! /bin/cp ${file_src} ${file_dst} ; then
        error_and_die "Failed to copy ${file_src} to ${file_dst}."
    fi
    return 0
}
