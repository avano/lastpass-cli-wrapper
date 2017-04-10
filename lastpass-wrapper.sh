#!/bin/bash
ACCOUNT=$1
ACTION=$2
SCRIPT_HOME=$(dirname "$(readlink -f "$0")")
source ${SCRIPT_HOME}/funcs.sh
ID=$(get_window_id)
URL=$(get_title_url ${ID})

# Get username and id string for rofi
get_username_id() {
    while IFS= read -r LINE ; do
        if [[ ! ${LINE} == "Multiple matches found"* ]];
        then
            LPASS_ID=$(echo ${LINE} | grep -oE "[0-9]{19}")
            USERNAME=$(lpass show --username ${LPASS_ID})
            echo "$USERNAME [id: $LPASS_ID]"
        fi
    done <<< "$1"
}

# Print username and hit TAB
input_username() {
    xdotool type "$1"
    xdotool key Tab
}

# Print password and clear clipboard
input_password() {
    lpass show -p $1 | xclip -selection clipboard && sleep .25; xdotool type "$(xclip -o -selection clipboard)" && xclip -selection clipboard -i /dev/null
}

# Parse ID and username from the string (one line from rofi input will be selected and passed as output)
parse_id_username() {
    LPASS_ID=$(echo "$1" | grep -oE "[0-9]{19}")
    USERNAME=$(echo "$1" | awk '{print $1;}')
    echo "${LPASS_ID} ${USERNAME}"
}

# Print username and password
input_credentials() {
    if [ $# -lt 2 ]; then
        # Only input
        input_username $(lpass show --username ${URL})
        input_password ${URL}
    else
        input_username $2
        input_password $1
    fi

}

get_user_for_url() {
    USER=$(lpass show --username ${URL})
    # If something went wrong, probably not logged in
    if [ $? -ne 0 ]; then
        lpass login ${ACCOUNT}
        USER=$(lpass show --username ${URL})
    fi
    echo "${USER}"
}

get_user_string() {
    USER=$(get_user_for_url)

    # Not found if empty, do nothing
    if [ -z "$USER" ]; then
        exit 0
    fi

    # If multiple matches found for the URL
    if [[ ${USER} == "Multiple matches found"* ]];
    then
        USER_ID=$(get_username_id "$USER"| rofi -dmenu -p "Select account for $URL:")
        if [[ ${USER_ID} == "Multiple matches found"* ]];
        then
            # Nothing was selected, exit
            exit 0
        fi
    fi
    if [ -z "$USER_ID" ];
    then
        # Only one option
        echo ""
    else
        # Parse
        echo "$(parse_id_username "${USER_ID}")"
    fi
}

get_password() {
    USER_STRING=$(get_user_string)
    if [ -z "${USER_STRING}" ];
    then
        input_password ${URL}
    else
        input_password $(parse_id_username "${USER_STRING}")
    fi
}

get_user_password() {
    USER_STRING=$(get_user_string)
    if [ -z "${USER_STRING}" ];
    then
        input_credentials ${URL}
    else
        input_credentials ${USER_STRING}
    fi
}

main() {
    case "$2" in
        "get-password")
            get_password
        ;;
        "get-user-password")
            get_user_password
        ;;
        "generate")
            echo "create"
        ;;
        "record")
            echo "record"
        ;;
        *)
            echo "You have failed to specify what to do correctly."
            exit 1
        ;;
    esac
}

main "$@"
exit 0
