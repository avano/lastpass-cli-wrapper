#!/bin/bash
ACCOUNT=$1
ACTION=$2
SCRIPT_HOME=$(dirname "$(readlink -f "$0")")
set -x
get_window_id() {
    echo "$(wmctrl -l | grep -oP "(0x\w+)(?=.* [C]hrome)")"
}

get_title_url() {
    echo "$(xprop -id $1 | grep "_NET_WM_NAME" | perl -ne '/\".* - (www.*\.)?(.*\.[a-zA-Z]{2,3})/ && print "$2"')"
}

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
paste_password() {
    lpass show -p $1 | xclip -selection clipboard && sleep .25; xdotool type "$(xclip -o -selection clipboard)" && xclip -selection clipboard -i /dev/null
    exit 0
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
        paste_password ${URL}
    else
        input_username $2
        paste_password $1
    fi

}

get_user_for_url() {
    USER=$(lpass show --username ${URL} 2>&1)
    echo "${USER}"
}

get_id_for_url() {
    ID=$(lpass ls | grep ${URL})
    if [[ $(echo ${ID} | wc -l) -ne 1 ]]; then
        USER_ID=$(get_user_from_rofi)
        echo ${USER_ID} | grep -oE "[0-9]{1,19}"
    else
        echo ${ID} | grep -oE "[0-9]{1,19}"
    fi
}

get_user_from_rofi() {
    USER_ID=$(get_username_id "$USER"| rofi -dmenu -p "Select account for $URL:")
    if [[ ${USER_ID} == "Multiple matches found"* ]];
        then
            # Nothing was selected, exit
            exit 0
        fi
    echo ${USER_ID}
}

get_user_string() {
    USER=$(get_user_for_url)

    # Not found if empty, do nothing
    if [ -z "$USER" ]; then
        exit 1
    fi

    # If multiple matches found for the URL
    if [[ ${USER} == "Multiple matches found"* ]];
    then
        USER_ID=$(get_user_from_rofi)
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

input_password() {
    USER_STRING=$(get_user_string)
    if [ -z "${USER_STRING}" ];
    then
        paste_password ${URL}
        exit 0
    else
        paste_password $(parse_id_username "${USER_STRING}")
    fi
    exit 0
}

input_user_password() {
    USER_STRING=$(get_user_string)
    if [ -z "${USER_STRING}" ];
    then
        input_credentials ${URL}
    else
        input_credentials ${USER_STRING}
    fi
}

record_credentials() {
    rm -f /tmp/keys.log
    python ${SCRIPT_HOME}/keylogger.py
    CREDENTIALS=$(cat /tmp/keys.log)
    USERNAME=$(echo ${CREDENTIALS%Tab*})
    if [[ ! ${CREDENTIALS} == *"Tab"* ]]; then
        # Only username supplied, pw will be generated

        PASSWORD=$(lpass generate --sync no tmp_placeholder 15)
        # Change backslash to forward slash and % to %%
        PASSWORD=$(echo ${PASSWORD} | sed 's#\\#\/#g' | sed 's#%#%%#g')
        # The command above will add a new record, so delete it because we will re-add it later
        lpass rm tmp_placeholder
    else
        PASSWORD=$(echo ${CREDENTIALS#*Tab})
    fi

    printf "Username: ${USERNAME}\nPassword: ${PASSWORD}\nURL: ${URL}" | lpass add --non-interactive ${URL}
    unset PASSWORD
}

check_lpass_session() {
    if [ $? -ne 0 ]; then
        if [[ ${USER} == *"Could not find specified account"* ]]; then
            exit 1
        fi
        lpass login ${ACCOUNT}
        USER=$(lpass show --username ${URL})
        if [ $? -ne 0 ]; then
            exit 1
        fi
    fi
}

main() {
    ID=$(get_window_id)
    URL=$(get_title_url ${ID} | grep -oE "[a-zA-Z0-9]+\.[a-zA-Z]{2,3}$")
    case "$2" in
        "input-password")
            check_lpass_session
            input_password
        ;;
        "input-user-password")
            check_lpass_session
            input_user_password
        ;;
        "record-credentials")
            record_credentials
        ;;
        *)
            echo "You have failed to specify what to do correctly."
            exit 1
        ;;
    esac
}

main "$@"
exit 0
