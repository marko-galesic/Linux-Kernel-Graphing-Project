#! /usr/bin/make

# This is the makefile to produce a CGI and the images for a navigable
# code map.

# Set the number of tiles across and down.  More means faster zooming,
# and less disk space
TILES_ACROSS:=4
TILES_DOWN:=5

# How many pixels across is the zoom window.
PIXELS_ACROSS:=400

# How many times can you zoom in?
MAX_ZOOM:=4

# How many levels down do we need to go before Ghostscript can render
# all the tiles in one go?
GSD:=2

## End of user-adjustable parameters.

CFLAGS:=-Wall -g #-O2
LDFLAGS:=-lpng

default: dir-tree seed-images lower-images upper-images

distclean: clean
	rm -rf ?x?

clean:
	rm -f split-images gather-image

# Make the directory tree
dir-tree:
	@echo Making directories...
	@./make-dirs.sh $(MAX_ZOOM) $(TILES_ACROSS) $(TILES_DOWN)

# Make the images off the Postscript.
seed-images: 
	@echo Making seed images...
	@set -e;							  \
	for d in `find . -type d -mindepth $(GSD) -maxdepth $(GSD)`; do	  \
	    if [ ! -f $$d.big.png ]; then				  \
		echo Making $$d.big.png;				  \
		./make-image.sh ../image.ps $(TILES_ACROSS) $(TILES_DOWN) \
		 `echo "$(PIXELS_ACROSS) * $(TILES_ACROSS) ^ 		  \
			( $(MAX_ZOOM) - $(GSD) )"|bc`			  \
		 `echo $$d | sed 's:^./::'` > $$d.big.png;		  \
	    fi;								  \
	done

# Make the images below that by cutting them up.
lower-images: split-image
	@echo Making images below that...
	@set -e; DIR=`pwd`;						\
	for d in `find . -type d -mindepth $(GSD)`; do			\
		echo Splitting $$d...;					\
		(cd $$d && $$DIR/split-image ../`basename $$d`.big.png	\
		 $(TILES_ACROSS) $(TILES_DOWN));			\
	done

# Make the images from the ones below them
upper-images: gather-image
	@echo Making images above that...
	set -e; DIR=`pwd`;						     \
	for d in `find . -type d -maxdepth $(GSD)`; do			     \
		(cd $$d && $DIR/gather-image $(TILES_ACROSS) $(TILES_DOWN)); \
	done

