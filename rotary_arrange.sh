#! /bin/sh

# Arrange files in circle, given spacing angle and each one's angle.
DIR_SPACING=$1
shift

BOUND=0
echo "% Rotary arrangement for $@"
echo gsave
while [ -n "$1" ]; do
    FILE="$1"
    ANGLE="`cat $2`"
    shift 2

    cat $FILE
    # Negative, because I screwed up sign in draw_arrangement.c
    ANGLE=`scale=2; echo $ANGLE + $DIR_SPACING | bc`
    echo -e "-$ANGLE rotate"
    echo "/angle angle $ANGLE add def"
    THIS_BOUND=`tail -n 1 $FILE | awk '{print $5}' | cut -d. -f1`
    if [ $THIS_BOUND -gt $BOUND ]; then BOUND=$THIS_BOUND; fi
done
echo grestore

# We assume it's circular.
echo "% bound -$BOUND -$BOUND $BOUND $BOUND"
