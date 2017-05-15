# Something-like-LastPass-extention-but-in-bash

a.k.a. lastpass-cli-wrapper

## What?

Allows you to input your passwords using xclip and xdotool and save your passwords in lastpass using [lastpass-cli](https://github.com/lastpass/lastpass-cli). In case of multiple account for given page, it uses [rofi](https://github.com/DaveDavenport/rofi) to choose between the accounts.

## Why?

Because the [LastPass extension can give out your passwords](https://www.engadget.com/2017/03/22/critical-exploits-found-in-lastpass-on-chrome-firefox/). And it is convenient to use keyboard shortcuts.

## Prerequisites

* LastPass-cli
* Rofi
* Python 2.7 (maybe others as well)

## How to use?

Either:
 * use Google Chrome + [Url in title](https://chrome.google.com/webstore/detail/url-in-title/ignpacbgnbnkaiooknalneoeladjnfgb?hl=en) with format `{title} - {hostname}`
 * or or change [some code](https://github.com/avano/lastpass-cli-wrapper/blob/master/lastpass-wrapper.sh#L6-L12) to parse the currently opened url in your browser

Then you can use:

`lastpass-wrapper.sh <YOUR_LASTPASS_EMAIL> <OPERATION>`

where OPERATION can be:
* input-password : automatically inputs the password for given page
* input-user-password : automatically inputs user, TAB, password
* record-credentials : saves your credentials for given page, expected format is `usernameTABpasswordENTER` when you want to store your current password or `usernameLEFT_CONTROL` if you want to have a password generated for you (you can use input-password afterwards)

## Drawbacks

Currently it works only for one browser window (probably the first one found in wmctrl output) and many failures in different cases.

## Last words

I'm not bash nor security expert.
