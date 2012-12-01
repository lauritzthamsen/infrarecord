#!/bin/bash

if [ `uname -s` = "Linux" ]; then
    ln infrared_plugin.py ~/.config/sublime-text-2/Packages/User/infrared_plugin.py
else
    echo Don\'t know where to link
fi
