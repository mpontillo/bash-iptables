#!/bin/bash

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    echo "Please source this script. For example:"
    echo "    . ${BASH_SOURCE[0]}"
fi

# Show commands for readable, complete `iptables` output with line numbers.
function show-iptable {
    table="$1"
    if [ "$table" == "" ]; then
        table="filter"
    fi
    printf "+=====================================+\n"
    printf "| Table: %-28s |\n" "$table"
    printf "+=====================================+\n"
    iptables -t "$table" -L -n -v --line-numbers
    echo ""
    echo ""
}

function show-iptables {
    TABLES="$(cat /proc/net/ip_tables_names)"
    for table in $TABLES; do
        show-iptable "$table"
    done
}

function _IPTABLES_is_numeric {
    case "$1" in
        ''|*[!0-9]*)
            false
            ;;
        *)
            true
            ;;
    esac
}

function add-iptables-rule {
    # The first argument must specify the table name. If the first argument
    # starts with a '-', it will be considered an action, and the default
    # table (filter) will be used.
    #
    # Subsequent arguments must be an add action (such as -A or -I) and its
    # pramaters.
    #
    # This function will replace the subsequent argument with a -C (check)
    # action, which will prevent a duplicate rule from being added.
    local table="$1"
    case $table in
        -*)
            table="filter"
        ;;
        *)
            shift
        ;;
    esac
    local action="$1"
    shift
    local chain="$1"
    shift
    if [ "$table" == "" -o "$action" == "" -o "$chain" == "" -o "$*" == "" ]; then
        printf \
            "Usage:\n"`
           `"    $FUNCNAME [table (default=filter)] <action-parameter>"`
           `" <chain> [rulenum] <rule-specification>\n"
        false
        return
    fi
    local rulenum=" "
    if _IPTABLES_is_numeric "$1"; then
        rulenum=" $1 "
        shift
    fi
    iptables_error="$(iptables -t "$table" -C "$chain" "$@" 2>&1 > /dev/null)"
    case $? in
        0)
            echo "Rule already exists." 1>&2
        ;;
        1)
            iptables -t "$table" "$action" "$chain"$rulenum"$@"
        ;;
        *)
            echo "iptables returned $?: $iptables_error" 1>&2
        ;;
    esac
}
