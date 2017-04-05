#!/bin/bash

get_window_id() {
    echo "$(wmctrl -l | grep -oP "(?<=)(0x\w+)(?=.*[C]hrome)")"
}

get_title_url() {
    echo "$(xprop -id $1 | grep "_NET_WM_NAME" | perl -ne '/\".* - (www.*\.)?(.*\.[a-zA-Z]{2,3})/ && print "$2"')"
}

get_username_id() {
    while IFS= read -r LINE ; do 
        if [[ ! $LINE == "Multiple matches found"* ]];
        then
            LPASS_ID=$(echo $LINE | grep -oE "[0-9]{19}")
            USERNAME=$(lpass show --username $LPASS_ID)
            echo "$USERNAME [id: $LPASS_ID]"
        fi
    done <<< "$1"
}

input_credentials() {
    xdotool type "$2"
    xdotool key Tab
    lpass show -p $1 | xclip -selection clipboard && sleep .25; xdotool type "$(xclip -o -selection clipboard)" && xclip -selection clipboard -i /dev/null
}

parse_input_credentials() {
    LPASS_ID=$(echo "$1" | grep -oE "[0-9]{19}")
    USERNAME=$(echo "$1" | awk '{print $1;}')
    input_credentials $LPASS_ID $USERNAME
}

main() {
    ID=$(get_window_id)
    URL=$(get_title_url $ID)

    USER=$(lpass show --username $URL)

    # If something went wrong, probably not logged in
    if [ $? -ne 0 ]; then
        lpass login vanoandrej@gmail.com
        USER=$(lpass show --username $URL)
    fi

    # Not found if empty, do nothing
    if [ -z "$USER" ]; then
        exit 0
    fi

    # If multiple matches found for the URL
    if [[ $USER == "Multiple matches found"* ]];
    then
        USER_ID=$(get_username_id "$USER"| rofi -dmenu -p "Select account for $URL:")
        if [[ $USER_ID == "Multiple matches found"* ]];
        then
            # Nothing was selected, exit
            exit 0
        fi
    fi
    if [ -z "$USER_ID" ];
    then
        # Only one option
        input_credentials $URL $USER
    else
        # Parse
        parse_input_credentials "$USER_ID"
    fi
}

main
exit 0
