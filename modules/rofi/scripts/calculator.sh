#!/usr/bin/env bash

# Handle script mode protocol for Rofi
if [ -z "$ROFI_RETV" ]; then
    # Initial launch - show prompt
    echo -en "\0prompt\x1fCalculate\n"
else
    # When user enters an expression
    expression="$1"

    # Calculate result using bc
    result=$(echo "scale=4; $expression" | bc -l 2>&1)

    # Output result back to Rofi
    echo "$expression = $result"
    echo "$result" | wl-copy
fi
