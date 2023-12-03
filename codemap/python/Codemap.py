#! /usr/bin/python2

# Copyright (C) 2001-2002 by Martin Pool <mbp@samba.org>

"""
A reimplementation of Rusty's Linux Graphing Project code.

We always work in the standard Postscript coordinate system, to more
easily allow later mapping from mouse clicks into items on the graph.
There are 72 basis points per inch, and we work in a 10x10 inch space.
"""

from sys import stdout, stderr
from ps import *

def draw_coords():

    """Draw Postscript coordinates bounding our space"""
    setlinewidth(1.0/4)
    setoff = DPI/8/4
    moveto(setoff, setoff)
    lineto(setoff, PAGE_H-setoff)
    lineto(PAGE_W-setoff, PAGE_H-setoff)
    lineto(PAGE_W-setoff, setoff)
    lineto(setoff, setoff)
    stroke()

    for i in range(1, PAGE_W/DPI):
        p = i*DPI
        eighth = DPI/8
        teenth = DPI/16
        
        moveto(setoff, p)
        lineto(eighth, p)
        
        moveto(PAGE_W, p)
        lineto(PAGE_W - eighth, p)

        moveto(p, setoff)
        lineto(p, eighth)

        moveto(p, PAGE_H)
        lineto(p, PAGE_W - eighth)

        # small marks along horizontal center axis
        moveto(p, CENTER-teenth)
        lineto(p, CENTER+teenth)

        # small marks along vertical center axis
        moveto(CENTER-teenth, p)
        lineto(CENTER+teenth, p)

    stroke()


def draw_sector(a1, a2, r1, r2, text, rgb):
    
    """Draw a sector on the pie, from radius 1 to radius 2 and angle1
    to angle2, with text somewhere near the center.  The inner arc is
    not drawn."""

    setblack()
    arc(CENTER, CENTER, r1, a1, a2)
    arc(CENTER, CENTER, r2, -a2, -a1)
    # arc(CENTER, CENTER, r1, a1, a1)

    # TODO: Draw text
#    gsave()
    setrgbcolor(rgb)
    fill()
#    grestore()
    #stroke()
    

    

def draw_toplevel():

    """Draw a toplevel graph of the Linux kernel.  Image is sent
    stdout as PostScript."""

    setlinewidth(2.0)

    arc(PAGE_W/2, PAGE_H/2, 1*DPI, 0, 360)
    stroke()

    setfontbyname("Helvetica-Oblique", 20)
    showtext(PAGE_W/2, PAGE_H/2, "linux")
    stroke()

#    a1 = 0
#    for a2 in (45, 130, 150, 220, 260, 330, 360):
#        draw_sector(a1, a2, 1*DPI, 2*DPI, "foo", (1.0, .2, .2))
#        a1 = a2

    draw_sector(0, 45, 1*DPI, 2*DPI, "foo", (.7, .2, .2))


adsc_header()
draw_coords()
draw_toplevel()
showpage()
adsc_trailer()
