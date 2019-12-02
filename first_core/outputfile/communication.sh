#!/bin/bash
stty -F /dev/ttyS4 9600
stty -F /dev/ttyS4 raw
stty -F /dev/ttyS4 -iexten
cat $1 > /dev/ttyS4 | cat /dev/ttyS4 > $2
