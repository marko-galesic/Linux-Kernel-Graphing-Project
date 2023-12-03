<?
require('libfcgp.php');
$title = 'About the KernelMapper';
print_header($title);
?>

<h1>About the KernelMapper</h1>

<h2>What it means</h2>

<p>A mystic mandala, or strange computer-generated art, or a map to
guide your explorations?  The kernel map has elements of all of these.

<p>The map is a figurative rather than exact representation of the
kernel.  We don't expect people to refer to it while they're working
on the kernel.  If it helps people to understand the different
subsystems, or to see the knottiness of different bits of code, or
perhaps to fondly discover the little corner they've touched we will
be pleased.

<p>Broadly, the division of the map into segments represents the
highest level division of the kernel code into subdirectories.  The
innermost circle, around Tux, is appropriately enough the
<tt>kernel/</tt> and <tt>mm/</tt> directories, which manage memory and
processes, the most fundamental objects.  In the next ring out are the
filesystem and networking layers.  The third ring contains
architecture-specific code for various systems, with one segment for
each.  It's clear here that some systems require much more
platform-specific code than others.

<p>The bulk of the code is device drivers, shown in the outermost
ring.

<p>Black squares represent source files, with the size of the square
proportional to the number of lines in the file.  Files are sorted by
size within each segment.

<p>Within each file there are rectangles for each function above a
minimum size.  These are coded red, green, and blue according to
whether the function is exported, indirect or static, or other.  Arcs
within the function represent its control flow: functions with a
single arc are probably straight-line code, while functions that look
knotty probably are.


<h2>How it works</h2>

<p>The kernel map is a fair attempt at setting a record for the number
of different tools and languages for a project of this size.  You can
see this either as validation of the power of using open standards to
enable a toolbox approach, or as evidence of the mental instability of
the authors. :-)

<p>The kernel map software performs static analysis of a Linux kernel
source tree.  The results of the analysis are eventually digested in
to a single 28MB Postscript file, containing the whole poster in
vector form.  This is done by a combination of two lex scanners, Perl
scripts, Bourne shell scripts, and a Makefile to guide the whole
thing.  Postscript is produced directly by print statements.

<p>For display on the web, the postscript file must be rendered into
bitmaps.  Because of the complexity of the vector file, rasterizing it
on demand would be completely infeasible: running it through
Postscript takes a couple of minutes on a fast machine.  On the other
hand, rendering it into a single large bitmap would be problematic
anyhow because at a reasonable level of detail that bitmap would be
hundreds of megabytes.

<p>This system rasterizes the map into bitmap "tiles" at various
levels of detail, which are then split into 200x200 "subtiles", stored
as PNGs.  All of this processing was performed ahead of time, so that
the images can be served straight from disk to the browser.
Rasterization is done by <a
href="http://www.ghostscript.com/">Ghostscript</a>, controlled by a
set of <a href="http://www.python.org/">Python</a> and shell scripts.
Splitting of tiles into subtiles is done by a small C program using <a
href="http://www.libpng.org/pub/png/libpng.html">libpng</a>.

<p>As a small optimization, a Python program looks for identical
subtile files, which are typically white space.  These are replaced
by hard links to a single file to save disk space, and, more
importantly, memory.

<p>The tiles are composed by a set of PHP scripts which produce HTML
that stitches together the appropriate images, and manages scrolling,
zooming, and so on.

<p>All of the source will shortly be available from the <a
href="http://fcgp.sourceforge.net/">Free Code Graphing Project</a> on
<a href="http://www.sourceforge.net/">SourceForge.net</a>.



<h2>Future projects</h2>

<p>Understanding and representing large software projects is very much an
open research project.  Gaining a good understanding of how the whole
kernel works can take months or years; probably nobody understands
every part of it in detail.

<p>Open source projects introduce additional levels of complexity:
authors come and go, and specialize in different areas that can be
hard to pin down.  Open source projects can release new versions very
rapidly, so the changes from one version to another are in themselves
interesting.

<p>Graphical displays can allow people to get an overview of a complex
situation quickly and then zoom closer for detail.  A great challenge
in representing a code base this way is discovering the important
relationships, so that the map is not swamped with irrelevant detail.

<p>Different maps are probably needed for different purposes: somebody
starting to learn their way around the kernel might want a sanitized
and abstracted view that shows clean layers even when they are not
quite so in practice.  Somebody debugging a problem might be crucially
interested in where the exceptions to general patterns lie.

<p>Static analysis is not the only possible input to mapping.  Showing
the way locks are held, or where time is spent in execution, or how
the kernel has changed in recent releases might also be useful, or at
least entertaining.

<p>And this is not even to mention the possibilities for interactive
exploration, perhaps using something like <a
href="http://touchgraph.sourceforge.net/">TouchGraph</a>.

<p>The problem can perhaps be divided into two parts: firstly, mining
interesting information from a codebase, and secondly converting it
into an easily-understandable form.  Both of them are important, and
both are difficult.  

<p>People have made good progress in recent years by using things such
as a the excellent <a href="http://www.graphviz.org/">GraphViz</a>
toolkit, which provides a very quick path through the second stage.
But GraphViz's approach seems to run out of conceptual steam for very
large numbers of nodes.

<p>We hope that the online availability of the map might encourage people
to further research and hackery in this area.

<p>Some more detailed notes on improving the functionality and
performance of the map are on the <a
href="http://fcgp.sourceforge.net/">FCGP homepage</a>.




<h2>Sponsors</h2>

<p><a href="http://www.linuxcare.com/">Linuxcare</a> supported Rusty in his initial work on the code map.

<p>The <a href="http://www.bcg.com/">Boston Consulting Group</a> and
<a href="http://www.osdn.com/">OSDN</a> supported conversion to a web map and hosting.

<p>You can buy full-size printed posters from <a href="http://thinkgeek.com/stuff/fun-stuff/3884.shtml">ThinkGeek</a>.
(This is much easier than printing it yourself, believe me!)



<h2>Developers</h2>

<p>
<a href="http://www.rustcorp.com.au/~rusty/">Paul "Rusty" Russell</a>
wrote the initial version of the mapping code; <a
href="http://sourcefrog.net/~mbp/">Martin Pool</a> finished the web
conversion; Karim Lakhani organized and initiated the project.  

<p>None of this would have been possible without the efforts of the
many free software developers whose work it builds upon.


<p><a href="map.php">Back to the map</a></center>


<p><A href="http://sourceforge.net"><img
src="http://sourceforge.net/sflogo.php?group_id=20623&type=1"
width="88"
height="31" border="0" alt="SourceForge Logo"></A></p>

</body>
</html>

