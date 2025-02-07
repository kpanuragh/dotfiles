#!/bin/bash

#=======================================================================================
# Transforms cava music visualizer into a desktop decoration in i3wm
# Dependencies: xdotool, cava, URxvt, i3-msg
#=======================================================================================

# Set screen resolution
Xscreen=$(xdpyinfo | awk '/dimensions/{print $2}' | cut -d'x' -f1)
Yscreen=$(xdpyinfo | awk '/dimensions/{print $2}' | cut -d'x' -f2)

# Offset applied to the window's vertical position
offset=20

# Height of the cava panel
h=200

# Cava config file (leave empty for default)
cavaConf=''

# Transparency settings
inCol='5'
outCol='[80]#fd971f'

# Mouse check interval (seconds)
mouseDelay=0.3

# File check interval (seconds)
fileCheck=0.1

# Animation transition time (seconds)
trTime=0.01

# Pixels per frame in transition
trPixel=10

# Process parameters
if [ ! -z "$cavaConf" ]; then
    cavaConf=" -p $cavaConf"
fi
if [ ! -z "$inCol" ] && [ ! -z "$outCol" ]; then
    inCol=" --color$inCol"
    outCol=" $outCol"
else
    inCol=''
    outCol=''
fi

# Check if the script is already running
if [ $# -eq 0 ]; then
    if pgrep -f "urxvt.*cava"; then
        echo "Found another instance, killing it..."
        pkill -f "urxvt.*cava"
        exit
    else
        echo "Starting the visualizer..."
        setsid $0 start >/dev/null 2>&1 < /dev/null &
        exit
    fi
elif [ "$1" = "start" ]; then
    echo $$ > /tmp/cava_pid
    isTriggeredFile='/tmp/isTriggered'
    echo 0 > $isTriggeredFile

    # Start URxvt with cava
    urxvt -name cava -bg "[0]red"$inCol$outCol -b 0 -depth 32 +sb -e cava$cavaConf &
    sleep 0.5  # Give URxvt time to start

    # Move it and set i3 rules
    i3-msg "[instance=\"cava\"] floating enable, border none, move absolute position 0 px $(($Yscreen - $h + $offset)) px, sticky enable, no_focus, opacity 0.8, below"

    # Get the window ID
    sleep 0.5
    wId=$(xdotool search --class "cava")

    # Hide on mouse hover
    xdotool behave $wId mouse-enter windowmove x $Yscreen exec "echo 1 > $isTriggeredFile" > /dev/null &
    echo $! >> /tmp/cava_pid

    # Infinite loop to show/hide
    while true; do
        while [ "$(cat $isTriggeredFile)" = "0" ]; do
            sleep $fileCheck
        done
        echo 0 > $isTriggeredFile
        eval $(xdotool getmouselocation --shell)
        xdotool windowfocus $WINDOW
        cursorExited=0
        while [ $cursorExited -eq 0 ]; do
            eval $(xdotool getmouselocation --shell)
            if [ $Y -lt $(($Yscreen - $h + $offset)) ]; then
                cursorExited=1
                Yd=$Yscreen
                Ydefault=$(($Yscreen - $h + $offset))
                while [ $Yd -gt $Ydefault ]; do
                    Yd=$(($Yd - $trPixel))
                    sleep $trTime
                    xdotool windowmove $wId x $Yd
                done
                xdotool windowmove $wId x $Ydefault
            fi
            sleep $mouseDelay
        done
    done
fi

