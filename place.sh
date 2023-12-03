#! /bin/sh
# Code to output a translated postscript.

set -e

# Get bounds of the image we're relative to.
# eg. % bound -1538.51 -1552.25 1499.18 1645.42
LEFT_BOUND=`tail -n 1 $3 | awk '{ print $3 }'`
LOWER_BOUND=`tail -n 1 $3 | awk '{ print $4 }'`
RIGHT_BOUND=`tail -n 1 $3 | awk '{ print $5 }'`
UPPER_BOUND=`tail -n 1 $3 | awk '{ print $6 }'`
SIZE_2=`echo "($RIGHT_BOUND - $LEFT_BOUND)/2" | bc`
SIZE_4=`echo "($RIGHT_BOUND - $LEFT_BOUND)/4" | bc`
SIZE_8=`echo "($RIGHT_BOUND - $LEFT_BOUND)/8" | bc`
SIZE_16=`echo "($RIGHT_BOUND - $LEFT_BOUND)/16" | bc`

sed -e "s/__SIZE_2__/$SIZE_2/" -e "s/__SIZE_4__/$SIZE_4/" \
    -e "s/__SIZE_8__/$SIZE_8/" -e "s/__SIZE_16__/$SIZE_16/" \
	< $2 > temp

case "$1"
in
    bottom-right)
	MY_RIGHT_BOUND=`tail -n 1 temp | awk '{ print $5 }'`
	MY_LOWER_BOUND=`tail -n 1 temp | awk '{ print $4 }'`
	echo "% Place at bottom right"
	echo gsave
	echo `echo "scale=2; $RIGHT_BOUND - $MY_RIGHT_BOUND" | bc` `echo "scale=2; $LOWER_BOUND - $MY_LOWER_BOUND" | bc` translate
	;;
    bottom-left)
	MY_LEFT_BOUND=`tail -n 1 temp | awk '{ print $3 }'`
	MY_LOWER_BOUND=`tail -n 1 temp | awk '{ print $4 }'`
	echo "% Place at bottom left"
	echo gsave
	echo `echo "scale=2; $LEFT_BOUND - $MY_LEFT_BOUND" | bc` `echo "scale=2; $LOWER_BOUND - $MY_LOWER_BOUND" | bc` translate
	;;
    below)
	MY_UPPER_BOUND=`tail -n 1 temp | awk '{ print $6 }'`
	MY_LOWER_BOUND=`tail -n 1 temp | awk '{ print $4 }'`
	echo "% Place below"
	echo gsave
	echo 0 `echo "scale=2; $LOWER_BOUND - $MY_UPPER_BOUND" | bc` translate
	LOWER_BOUND=`echo "scale=2; $LOWER_BOUND - $MY_UPPER_BOUND + $MY_LOWER_BOUND" | bc`
	;;
    above)
	MY_UPPER_BOUND=`tail -n 1 temp | awk '{ print $6 }'`
	MY_LOWER_BOUND=`tail -n 1 temp | awk '{ print $4 }'`
	echo "% Place above"
	echo gsave
	echo 0 `echo "scale=2; $UPPER_BOUND - $MY_LOWER_BOUND" | bc` translate
	UPPER_BOUND=`echo "scale=2; $UPPER_BOUND - $MY_LOWER_BOUND + $MY_UPPER_BOUND" | bc`
	;;
    *)
	echo place.sh: Unimplemented position "$1" >&2
	exit 1
        ;;
esac

cat temp
rm temp
echo grestore
echo "% bound $LEFT_BOUND $LOWER_BOUND $RIGHT_BOUND $UPPER_BOUND"
