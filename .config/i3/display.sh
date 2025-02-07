#!/bin/bash

# Get the list of connected monitors
connected_monitors=$(xrandr --query | grep " connected" | awk '{print $1}')

# Count the number of connected monitors
monitor_count=$(echo "$connected_monitors" | wc -l)

# Check if more than one monitor is connected
if [ "$monitor_count" -gt 1 ]; then
    # Disable eDP-1 if multiple monitors are detected
    xrandr --output eDP-1 --off
fi
