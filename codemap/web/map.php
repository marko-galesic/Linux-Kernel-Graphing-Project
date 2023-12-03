<? 

# Copyright (C) 2001, 2002 by Martin Pool <mbp@samba.org>

require('libfcgp.php');

function link_to($x, $y, $zoom, $label) {
  global $SCRIPT_NAME;
  print "<a href=\"$SCRIPT_NAME?x=$x&y=$y&zoom=$zoom\">$label</a>";
}


function link_perhaps($x, $y, $zoom, $label, $cond) {
  if ($cond)
    link_to($x, $y, $zoom, $label);
  else 
    print $label;
}

function icon_perhaps($x, $y, $zoom, $cond, $true_src, $false_src) {
  if ($cond)
    link_to($x, $y, $zoom, "<img border=0 src=\"$true_src\">");
  else 
    print "<img border=0 src=\"$false_src\">";
}


function tile_name($zoom, $x, $y, $ox, $oy) {
  return sprintf("../../tiles/zoom%03d/x%06d_y%06d/%06dx%06d.big.png",
		 $zoom, $x, $y, $ox, $oy);
}


function clip_zoom($zoom) {
  if ($zoom <= 1)
    return 1;
  else if ($zoom <= 2)
    return 2;
  else if ($zoom <= 4)
    return 4;
  else if ($zoom <= 8)
    return 8;
  else if ($zoom <= 16)
    return 16;
  else if ($zoom <= 32)
    return 32;
  else 
    return 64;
}


function print_zoom_scale($x, $y, $zoom) {
  print "<nobr><b>Zoom:&nbsp;</b>";
  foreach (array(1, 2, 4, 8, 16, 32, 64) as $z) {
    if ($zoom == $z) {
      print "<img src=\"circle_small_dark.png\" border=\"0\" alt=\"$z\">";
    } else {
      $f = $z/$zoom;
      link_to($x*$f, $y*$f, $z, 
	      "<img src=\"circle_small.png\" border=\"0\" alt=\"$z\">");
    }
  }

  print "</nobr>\n";
}


print_header("The Linux Kernel Map");
print "<center>";
 
if (!isset($zoom)) $zoom = 1;
if (!isset($x)) $x = 0;
if (!isset($y)) $y = 0;

// The image tiles are a constant size, but by changing the number
// displayed on the screen you can effectively change the size of the
// scrolling window.
$wt_x = 4;
$wt_y = 3;

$base_w = 600;
$base_h = 600;
$sub_w = 200;
$sub_h = 200;
$max_multiple = 8;


function tile_img($zoom, $rx, $ry, $ox, $oy)
{
  global $sub_w, $sub_h;
  return ("<img height=\"$sub_h\" width=\"$sub_w\" border=\"0\" src=\""
	 . tile_name($zoom, $rx, $ry, $ox, $oy) . "\">");
}

$zoom = clip_zoom($zoom);

// Overall size of the map
$map_w = $base_w * $zoom;
$map_h = $base_h * $zoom;

// This has to match up with the maketiles code:

// $max_multiple is the largest zoom at which we're willing to generate 
// only one coarse tile.

$max_multiple = 8;
if ($zoom > $max_multiple) {
  $n_split = $zoom / $max_multiple;
  $coarse_w = $base_w * $max_multiple;
  $coarse_h = $base_h * $max_multiple;

  // In this region, as we zoom in we get more and more fine tiles and
  // so they each actually cover less pixels.
  $fine_w = $sub_w;
  $fine_h = $sub_h;
} else {
  $n_split = 1;
  $coarse_w = $base_w * $zoom;
  $coarse_h = $base_h * $zoom;
  $fine_w = $sub_w;
  $fine_h = $sub_h;
}

// At this level of zoom, coarse tiles are coarse_w x coarse_h, and
// subdivided in each direction into $n_split fine tiles, each of
// which covers $fine_w x $fine_h units.

// At one point, the code tried to make the arrows scroll by just less
// than a whole page, with one tile of overlap.  This is practical for
// quick navigation, but it ends up feeling quite clumsy.  So instead
// we move by the smallest possible step at each stage.

$xstep = $fine_w;    //  * max(1, ($wt_x - 1));
$ystep = $fine_h;    // * max(1, ($wt_y - 1));

$window_w = $wt_x * $fine_w;
$window_h = $wt_y * $fine_h;

// Push the view back within the boundaries; save as $ox
$ox = $x; $oy = $y;
if ($x < 0) {
  $x = 0;
} else if ($x + $window_w > $map_w) {
  $x = $map_w - $window_w;
}

if ($y < 0) {
  $y = 0;
} else if ($y + $window_h > $map_h) {
  $y = $map_h - $window_h;
}

// TODO: Only show links that point somewhere valid and different to
// the current view

// The URL parameters for x and y point to the middle of the window.
// Adjust them to point to the bottom left.  It's OK if this puts us
// off the edge, because we'll adjust later.

$bx = $x; // - $window_w / 2;
$by = $y;// - $window_h / 2;


// Our end goal is to show the map with x,y in the bottom corner.  We
// need to map from these coordinates and the oom level to a set of
// coarse and fine-grained coordinates.  Note that we may lie over the
// edge of a coase-grained tile.

// Both are measured from the top left, but the fine-grained tiles are
// not measured in points but rather by index within their coarse
// tile.

// TODO: Make sure we don't try to link to tiles that don't exist!

print "<!-- overall table --><tr>\n";
print "<table border=0>\n"; 
print "<td valign=top align=left>\n";
print "<!-- Little left column with navigation stuff -->\n";
link_to(0, 0, 1, "Home"); 
print "<br>";
link_to(0, 4840, 8, "Key");
print "<br>";
print "<a href=\"quicklinks.php\">Quick links</a>";
print "<br>";
print "<a href=\"about.php\">About</a>";

print "<p>\n";
print_zoom_scale($x, $y, $zoom);

print "<p>\n";
?>
<p><A href="http://sourceforge.net"><img src="http://sourceforge.net/sflogo.php?group_id=20623&type=1" width="88" height="31" border="0" alt="SourceForge Logo"></A></p>
<?

print "<td>\n";
print "<!-- table containing tiles being displayed -->";
// must be no extra whitespace in here
print "<table cellpadding=0 cellspacing=0 border=0>";
print "<!-- top row -->";

print "<tr>";
// colspan is 2 because we need to include the two extra
// columns for the left/right arrows
print "<td align=\"center\" colspan=\"" . (2+$wt_x) . "\">";
icon_perhaps($x, $y-$ystep, $zoom, $oy > 0,
	     "arrow_up.png", "circle.png");
print "</tr>";

for ($dy = 0; $dy < $wt_y; $dy++) {
  $ty = $by + $dy * $fine_h;

  if ($ty < 0 || $ty >= $map_h)
    continue;

  print "<tr>";

  if ($dy == 0) {
    print "<!-- left-navigation arrow -->";
    print "<td rowspan=\"$wt_y\">";
    /* We allow scrolling if we're not already on the far edge. */
    icon_perhaps($x-$xstep, $y, $zoom, $ox > 0,
		 "arrow_left.png", "circle.png");
    print "</td>";
  }

  for ($dx = 0; $dx < $wt_x; $dx++) {
    // Absolute position of this tile
    $tx = $bx + $dx * $fine_w;

    if ($tx < 0 || $tx >= $map_w)
      continue;

    print "<td>";

    // Now, work out which coarse tile it lies in.  Just as a final
    // complication, the y axis for the coarse tiles is inverted.

    $cx = ((int) ($tx / $coarse_w)) * $coarse_w;
    $cy = ($n_split - ((int) ($ty / $coarse_h)) - 1) * $coarse_h;

    // And which fine tile within that
    $fx = (int) (($tx % $coarse_w) / $fine_w);
    $fy = (int) (($ty % $coarse_h) / $fine_h);

    // Work out where this tile is so that we can zoom onto it
    $tile_str = tile_img($zoom, $cx, $cy, $fx, $fy);
    if ($zoom < 64) {
      link_to($tx*2, $ty*2, $zoom*2, $tile_str);
    } else {
      print $tile_str;
    }
    printf("<!-- tx=%d ty=%d cx=%d cy=%d fx=%d fy=%d -->",
	   $tx, $ty, $cx, $cy, $fx, $fy);
    print "</td>";
  }

  if ($dy == 0) {
    print "<!-- right-navigation arrow -->";
    print "<td rowspan=\"$wt_y\">";
    icon_perhaps($x+$xstep, $y, $zoom, ($ox+$window_w) < $map_w,
		 "arrow_right.png", "circle.png");
    print "</td>";
  }

  print "</tr>";
}

print "<tr><td align=\"center\" colspan=\"" . (2+$wt_x) . "\">";
icon_perhaps($x, $y+$ystep, $zoom, ($oy+$window_h) < $map_h,
	     "arrow_down.png", "circle.png");
print "</td></tr>";

print "</table><!-- end map table -->\n";

print "</tr></table><!-- end overall table -->\n";

?>
</center>
</body>
</html>
