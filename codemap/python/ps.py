#! /usr/bin/python2

# Copyright (C) 2001-2002 by Martin Pool <mbp@samba.org>

DPI = 72.0
PAGE_W = 10 * DPI
PAGE_H = 10 * DPI
CENTER = PAGE_W/2

def setlinewidth(w):
    """Set line width to W points"""
    print "%f setlinewidth" % (w)

def arc(x, y, rad, start, end):
    print "%f %f %f %f %f arc" % (x, y, rad, start, end)

def setfontbyname(fname, scale):
    print "/%s findfont %f scalefont setfont" % (fname, scale)

def showtext(x, y, text):
    print "(%s) dup stringwidth" % (text) # -- string tw th
    print "exch 2 div %f exch sub" % (x)  # -- string th xx
    print "exch 2 div %f exch sub" % (y)  # -- string xx yy
    print "moveto show"

def moveto(x, y):
    print "%f %f moveto" % (x, y)

def lineto(x, y):
    print "%f %f lineto" % (x, y)

def showpage():
    print "showpage"
    
def stroke():
    print "stroke"

def fill():
    print "fill"

def strokepath():
    print "strokepath"

def setrgbcolor(rgb):
    print "%f %f %f setrgbcolor" % rgb

def setblack():
    setrgbcolor((0, 0, 0))

def gsave():
    print "gsave"

def grestore():
    print "grestore"

def adsc_header():
    print """%!PS-Adobe-2.0
%%Creator: Codemap
%%Title: codemap
%%BoundingBox: 0 0 720 720
%%EndComments
"""

def adsc_trailer():
    print "%%Trailer"

