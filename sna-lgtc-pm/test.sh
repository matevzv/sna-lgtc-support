hex2bin () {
    HEX=`printf "%02x" $1 | tr a-z A-Z`
    BIN=$(echo "obase=2; ibase=16; $HEX" | bc )
    BINLEN=${#BIN}

    if [ $BINLEN != 8 ]; then
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

INT=`hex2bin 0x07`
echo "$INT"

# get the third bit from the left 00100000
ACINT="${INT:2:1}"
if [ $ACINT == 0 ]; then
    # shift the third bit from the left 00100000
    MASK=`echo $INT | sed s/./1/3`
    # convert to hex and set i2c register
    MASK=`bin2hex $MASK`
    echo "$MASK"
fi
