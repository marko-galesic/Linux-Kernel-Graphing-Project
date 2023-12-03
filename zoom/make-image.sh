#! /bin/sh

# Args: POSTSCRIPT TILES-ACROSS TILES-DOWN PIXELS-ACROSS dir

# Failure is death
set -e

if [ $# -ne 5 ]; then
    echo Usage: make-image.sh MASTER TILES_ACROSS TILES_DOWN PIXELS_ACROSS dir >&2
    exit 1
fi

# Find original measurements from PostScript.
LEFT_BOUND=`tail -1 $1 | awk '{ print $3 }'`
LOWER_BOUND=`tail -1 $1 | awk '{ print $4 }'`
RIGHT_BOUND=`tail -1 $1 | awk '{ print $5 }'`
UPPER_BOUND=`tail -1 $1 | awk '{ print $6 }'`
ORIG_WIDTH=`echo $RIGHT_BOUND - $LEFT_BOUND | bc`
ORIG_HEIGHT=`echo $UPPER_BOUND - $LOWER_BOUND | bc`

X=$LEFT_BOUND
Y=$LOWER_BOUND
WIDTH=$ORIG_WIDTH
HEIGHT=$ORIG_HEIGHT

# Scale it so that tile we want is 1 inch (72 points) wide.
SCALE=`echo "scale=5; 72 / $ORIG_WIDTH" | bc`

# Every dir mentioned in the path reduces what we are rendering
for dir in `echo $5 | tr / ' '`; do
    x=`echo $dir | cut -dx -f1`
    y=`echo $dir | cut -dx -f2`
    WIDTH=`echo "$WIDTH / $2" | bc`
    X=`echo "$X + $x * $WIDTH" | bc`
    HEIGHT=`echo "$HEIGHT / $3" | bc`
    Y=`echo "$Y + $y * $HEIGHT" | bc`
    SCALE=`echo "$SCALE * $2" | bc`
done

# Height is calculated by a straight ratio.
# eg. if we had a 400x500 image, at 4*5 tiles, and PIXELS_ACROSS was 100,
# PIXELS_DOWN = 100 * (4/5) * (500/400) = 100.
# But do multiply first for better precision
PIXELS_DOWN=`echo "$4 * $2 * $ORIG_HEIGHT / $3 / $ORIG_WIDTH" | bc`

(echo $SCALE dup scale $X neg $Y neg translate; cat `dirname $1`/bindings.ps $1; echo showpage) |
  gs -sDEVICE=png256 -g${4}x${PIXELS_DOWN} -r$4 -quiet -sOutputFile=- -

#(echo $SCALE dup scale $X $Y translate; cat $1; echo showpage) |
#  gs -sDEVICE=png256 -g${2}x${PIXELS_DOWN} -r$2 -quiet -sOutputFile=- -


