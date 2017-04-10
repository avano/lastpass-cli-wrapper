#!/bin/bash

get_window_id() {
    echo "$(wmctrl -l | grep -oP "(?<=)(0x\w+)(?=.*[C]hrome)")"
}

get_title_url() {
    echo "$(xprop -id $1 | grep "_NET_WM_NAME" | perl -ne '/\".* - (www.*\.)?(.*\.[a-zA-Z]{2,3})/ && print "$2"')"
}
