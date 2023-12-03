#! /bin/sh
# Args: $(MAX_ZOOM) $(TILES_ACROSS) $(TILES_DOWN) 
if [ $# -eq 3 ]; then
    # Expand args once for everyone.
    ARGS=""
    x=0
    while [ $x -lt $2 ]; do
	y=0
	while [ $y -lt $3 ]; do
	    ARGS="$ARGS ${x}x${y}"
	    y=`expr $y + 1`
	done
	x=`expr $x + 1`
    done
    ./$0 $1 $ARGS
else
    # Bugger: expr uses exit status 1 to mean "zero result".
    DEPTH=`expr $1 - 1`
    set -e
    shift

    if [ $DEPTH -eq 0 ]; then exit 0; fi

    mkdir "$@"
    for d; do 
	(cd $d && ../$0 $DEPTH "$@")
    done
fi
