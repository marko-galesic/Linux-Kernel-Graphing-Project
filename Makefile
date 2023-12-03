#! /usr/bin/make

# Adjustable parameters

# How much to overlap files (eg. 0.5 = give them 50% of their size).
#FILE_SCRUNCH=0.8
FILE_SCRUNCH=1
# How much to overlap files to pack them into a small row
SMALL_ROW_SCRUNCH=0.9
# Max row size SMALL_ROW_SCRUNCH should try to create
SMALL_ROW_MAX=2
# How much to overlap functions.
#FUNCTION_SCRUNCH=0.9
FUNCTION_SCRUNCH=1
# Radius of inner area (where Tux goes).
INNER_RADIUS=200
# Spacing between segments (degrees).
DIR_SPACING=1
# Spacing between rings (pixels)
RING_SPACING=-100
# How much to scrunch boxes around files.
#BOX_SCRUNCH=0.8
BOX_SCRUNCH=1
# If a function is fewer than this many lines, skip.
YOU_MUST_BE_THIS_TALL_TO_BE_IN_POSTER=15

ifndef KERNEL_DIR
dummy:
	@echo You must set KERNEL_DIR.  Read README.
	@exit 1
endif

RING1:=init lib mm kernel ipc
RING2:=net fs
RING3:=$(subst $(KERNEL_DIR)/,,$(wildcard $(KERNEL_DIR)/arch/*))
RING4:=drivers crypto sound security
#RING4:=$(subst $(KERNEL_DIR)/,,$(wildcard $(KERNEL_DIR)/drivers/*)) 
#add mkdir image/drivers to use the split out drivers in ring 4

CFLAGS:=-Wall -O2

default: image.ps

stage2-clean:
	rm -f image/Makefile
	find image -name '*.ps' -o -name '*.angle' -o -name '*.weight' | xargs -r rm

clean:
	rm -f title.ps image.ps analyze_function.o analyze_function.c data2ps.o function2ps.o function2ps draw_arrangement rmclutter rmclutter.c *~

distclean: clean
	rm -rf image

function2ps: function2ps.o data2ps.o analyze_function.o
	$(CC) $(CFLAGS) -O -o $@ $^  -lfl -lm

function2ps.o: function2ps.c analyze_function.h
	$(CC) $(CFLAGS) -c -O -o $@ $<

data2ps.o: data2ps.c
	$(CC) $(CFLAGS) -c -O -o $@ $^

analyze_function.o: analyze_function.c
	$(CC) $(CFLAGS) -c -O -o $@ $^

rmclutter: rmclutter.c
	$(CC) $(CFLAGS) -O -o $@ $^ -lfl

conglomerate_functions: conglomerate_functions.c
	$(CC) $(CFLAGS) -O -o $@ $^ -lpng -lm

draw_arrangement: draw_arrangement.c
	$(CC) $(CFLAGS) -o $@ $^ -lm

merge_png: merge_png.c
	$(CC) $(CFLAGS) -o $@ $^ -lpng -lm

png_area: png_area.c
	$(CC) $(CFLAGS) -o $@ $^ -lpng -lm

draw_sector: draw_sector.c
	$(CC) $(CFLAGS) -o $@ $^ -lpng -lm

%.c: %.lex
	lex $^ && mv lex.yy.c $@

# We generate the image/ dir, and the Makefile in it.
image.ps: rmclutter function2ps draw_arrangement title.ps image image/ring1 image/ring2 image/ring3 image/ring4 image/nonstatics image/Makefile
	cd image && $(MAKE) image.ps
	@rm -f image.ps; ln -s image/image.ps .

# Generate title.ps from template.
title.ps: title-template.ps $(KERNEL_DIR)/Makefile
	@VERSION1=`grep "^VERSION =" $(KERNEL_DIR)/Makefile | sed 's/.*= \?//'`; \
	VERSION2=`grep "^PATCHLEVEL =" $(KERNEL_DIR)/Makefile | sed 's/.*= \?//'`; \
	VERSION3=`grep "^SUBLEVEL =" $(KERNEL_DIR)/Makefile | sed 's/.*= \?//'`; \
	VERSION4=`grep "^EXTRAVERSION =" $(KERNEL_DIR)/Makefile | sed 's/.*= \?//'`; \
	VERSION="$$VERSION1.$$VERSION2.$$VERSION3"; \
	if [ -n "$$VERSION4" ]; then VERSION="$$VERSION$$VERSION4"; fi; \
	sed "s/__VERSION__/$$VERSION/" < title-template.ps > $@; \
	echo Kernel version set to $$VERSION.

# Create Makefile.
image/Makefile: gen_makefile.sh
	@echo STAGE 2: Creating PostScript...
	FILE_SCRUNCH="$(FILE_SCRUNCH)" SMALL_ROW_SCRUNCH="$(SMALL_ROW_SCRUNCH)" SMALL_ROW_MAX="$(SMALL_ROW_MAX)" RING1="$(RING1)" RING2="$(RING2)" RING3="$(RING3)" RING4="$(RING4)" FUNCTION_SCRUNCH="$(FUNCTION_SCRUNCH)" BOX_SCRUNCH="$(BOX_SCRUNCH)" INNER_RADIUS=$(INNER_RADIUS) DIR_SPACING=$(DIR_SPACING) RING_SPACING=$(RING_SPACING) ./gen_makefile.sh > $@

define COPY_FUNCS
set -e; \
  ./setup_dirtree.pl $$RINGNO $(KERNEL_DIR) $$DIRS ; \
  ./extract_funcs.pl $(YOU_MUST_BE_THIS_TALL_TO_BE_IN_POSTER) $$RINGNO;
endef


# Copy functions over a certain size from kernel sources.
image:
	@mkdir image && mkdir image/arch #&& mkdir image/drivers

image/ring1:
	@echo STAGE 1: Function extraction and classification.
	@echo Copying ring1 functions from kernel directory...
	@DIRS="$(RING1)"; RINGNO="1"; $(COPY_FUNCS)
	@touch $@

image/ring2:
	@echo Copying ring2 functions from kernel directory...
	@DIRS="$(RING2)"; RINGNO="2"; $(COPY_FUNCS)
	@touch $@

image/ring3:
	@echo Copying ring3 functions from kernel directory...
	@DIRS="$(RING3)"; RINGNO="3"; $(COPY_FUNCS)
	@touch $@

image/ring4:
	@echo Copying ring4 functions from kernel directory...
	@DIRS="$(RING4)"; RINGNO="4"; $(COPY_FUNCS)
	@touch $@

image/nonstatics:
	@echo Classifying remaining nonstatics...
	@cd image; find $(RING1) $(RING2) $(RING3) $(RING4) -name '*.+NONSTATIC+.ps' | ../classify_nonstatics.pl $(KERNEL_DIR)
	@touch $@

nonstatic_count:
	@echo Counting functions classified as '"nonstatic"'
	@cd image; find $(RING1) $(RING2) $(RING3) $(RING4) -name '*.+NONSTATIC+' | wc -l
	@cd ..
