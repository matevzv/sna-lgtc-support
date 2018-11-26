#!/usr/bin/env bash

hex2bin () {
    HEX=`printf "%02x" $1 | tr a-z A-Z`
    BIN=$(echo "obase=2; ibase=16; $HEX" | bc )
    BINLEN=${#BIN}

    if [ "$BINLEN" != 8 ]; then
        BIN=`printf "0%.0s" $(eval echo "{1..$((8 - $BINLEN))}")`"$BIN"
    fi

    echo "$BIN"
}

bin2hex () {
    HEX=`printf '%x\n' "$((2#$1))"`

    if [ ${#HEX} -lt 2 ]; then
        HEX="0x0$HEX"
    else
        HEX="0x$HEX"
    fi

    echo "$HEX"
}

# disable PMIC AC interapt if not disabled
INT=`i2cget -f -y 0 0x24 0x02`
INT=`hex2bin "$INT"`
echo INTERRUPT register: "$INT"

# get the third bit from the left 00100000
echo AC interrupt: "${INT:2:1}"
ACINT="${INT:2:1}"
if [ "$ACINT" -eq 0 ]; then
    # shift the third bit from the left 00100000
    # AC interrupt turn off
    MASK="00100000"
    
    # convert to hex and set i2c register
    MASK=`bin2hex $MASK`
    echo hex mask: "$MASK"
    i2cset -f -y -m "$MASK" 0 0x24 0x02 "$MASK"

    # check if it worked
    INT=`i2cget -f -y 0 0x24 0x02`
    INT=`hex2bin "$INT"`
    echo INTERRUPT register: "$INT"

    # get the third bit from the left 00100000
    echo AC interrupt: "${INT:2:1}"
    ACINT="${INT:2:1}"
    if [ "$ACINT" -eq 1 ]; then
        echo AC interrupt switched off sucessfully
    else
        echo ERROR: Failed to switch off AC interrupt
        exit 1
    fi
fi

SHUTDOWN=false

while true; do
    # check the state of AC power status bit
    STATUS=`i2cget -f -y 0 0x24 0x0a`
    STATUS=`hex2bin "$STATUS"`
    echo STATUS register: "$STATUS"

    # get the fifth bit from the left 00001000
    echo AC status: "${STATUS:4:1}"
    AC="${STATUS:4:1}"

    if [ "$AC" -eq 0 ]; then
        # AC power was lost wait a while if it comes back
        echo Entering shutdown sequence
        if [ "$SHUTDOWN" = true ]; then
            poweroff
        else
            SHUTDOWN=true
            sleep 600
        fi
    else
        echo AC power OK
        SHUTDOWN=false
    fi

    sleep 10
done
