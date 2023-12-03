#! /bin/sh

# Arguments: inner circle diameter, angle divide, ring spacing, ring1
# We're in the image directory.  Do the lines.

echo "gsave"
echo "20 setlinewidth"
echo "0 0 0 setrgbcolor"

OUTLINE_SPACING=`echo "scale=2; $3 * 3" | bc`

RING1_BOUND=`tail -n 1 ring1.ps | awk '{print $5}'`
RING2_BOUND=`tail -n 1 ring2.ps | awk '{print $5}'`
RING3_BOUND=`tail -n 1 ring3.ps | awk '{print $5}'`
RING4_BOUND=`tail -n 1 ring4.ps | awk '{print $5}'`

# Add in some spacing (multiple of ring spacing).
RING1_BOUND=`echo "$RING1_BOUND + $OUTLINE_SPACING" | bc`
RING2_BOUND=`echo "$RING2_BOUND + $OUTLINE_SPACING" | bc`
RING3_BOUND=`echo "$RING3_BOUND + $OUTLINE_SPACING" | bc`
RING4_BOUND=`echo "$RING4_BOUND + $OUTLINE_SPACING" | bc`

# Draw circles.
echo "newpath"
echo "0 0 $1 0 360 arc"
echo "$RING1_BOUND 0 moveto"
echo "0 0 $RING1_BOUND 0 360 arc"
echo "$RING2_BOUND 0 moveto"
echo "0 0 $RING2_BOUND 0 360 arc"
echo "$RING3_BOUND 0 moveto"
echo "0 0 $RING3_BOUND 0 360 arc"
echo "$RING4_BOUND 0 moveto"
echo "0 0 $RING4_BOUND 0 360 arc"

# Label for inner ring.
#echo "-$RING1_BOUND -$RING1_BOUND moveto"
echo "`echo $1 + 100 | bc` -50 moveto"
echo "/Helvetica findfont"
echo "100 scalefont setfont"
echo "(`echo $4 | sed 's/ /, /g' | sed 's/^\(.*\),/\1 \& /'`) show"

# Draw ring2 dividers
# -ve because I screwed up in draw_arrangement.c
half=`echo "scale=2; $2 / 2" | bc`
remainder=0
echo gsave
# Rotate half back
echo "$half rotate"
echo "/angle $half neg def"
for f in `find . -name '*-ring2.angle' -print | sort`; do
    echo "$RING1_BOUND 0 moveto $RING2_BOUND 0 lineto stroke"
    echo `echo \( $RING2_BOUND + $RING1_BOUND \) / 2 | bc` -200 moveto
    echo "gsave angle rotate"
    echo "(`echo $f | sed -e 's/-ring2.angle//' -e 's:^./::'`) show"
    echo "grestore /angle angle `cat $f` $2 add add def"
    echo "-`cat $f` rotate"
    echo "-$2 rotate"
done
echo grestore

# Draw ring3 dividers
remainder=0
echo gsave
# Rotate half back
echo "$half rotate"
echo "/angle $half neg def"
for f in `find . -name '*-ring3.angle' -print | sort`; do
    echo "$RING2_BOUND 0 moveto $RING3_BOUND 0 lineto stroke"
    echo `echo \( $RING3_BOUND + $RING2_BOUND \) / 2 | bc` -200 moveto
    echo "gsave angle rotate"
    echo "(`echo $f | sed -e 's/-ring3.angle//' -e 's:^./::'`) show"
    echo "grestore /angle angle `cat $f` $2 add add def"
    echo "-`cat $f` rotate"
    echo "-$2 rotate"
done
echo grestore

# Draw ring4 label
#for f in `find . -name '*-ring4.ps'`; do
#    echo `echo \( $RING4_BOUND + $RING3_BOUND \) / 2 | bc` -200 moveto
#    echo "(`echo $f | sed 's/-ring4.ps//'`) show"
#done

# Draw ring4 dividers
remainder=0
echo gsave
# Rotate half back
echo "$half rotate"
echo "/angle $half neg def"
for f in `find . -name '*-ring4.angle' | sort`; do
    if [ `find . -name '*-ring4.angle' | wc -w` -gt 1 ]; then
        echo "$RING3_BOUND 0 moveto $RING4_BOUND 0 lineto stroke"
    fi
    echo `echo \( $RING4_BOUND + $RING3_BOUND \) / 2 | bc` -200 moveto
    echo "gsave angle rotate"
    echo "(`echo $f | sed -e 's/-ring4.angle//' -e 's:^./::'`) show"
    echo "grestore /angle angle `cat $f` $2 add add def"
    echo "-`cat $f` rotate"
    echo "-$2 rotate"
done
echo grestore

echo "stroke"
echo "grestore"
