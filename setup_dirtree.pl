#!/usr/bin/perl -w
#
# Setup the image/ directory tree and get the names of all source files to be
# processed (these are saved as one filename per line in image/ringX-files
# (no pun intended - X = 1..4 :)
#
# Cmdline arguments:
#   * Ring Number
#   * Kernel dir
#   * Toplevel directories to use ($RINGX from Makefile)
#
# All paths are internally handled relative to KernelDir (and ./image/)
#

use strict;


my $RingNo    = shift @ARGV;
my $KernelDir = shift @ARGV;
my @TLDirs    = @ARGV;

my $FNFile;        # File to write C file names to
my $CFNFile;       # Same as $FNFile, but here we include the complete path
                   # (including KernelDir)

my @CDirName = (); # stack with the current dir name/path
my $CTLDir;        # current toplevel dir


SafeMkdir ("./image");

open (FN_FILE,  ">./image/ring${RingNo}-files")
        or die ("Could not open './image/ring${RingNo}-files' for writing");

open (CFN_FILE, ">./image/ring${RingNo}-files-absolute")
        or die ("Could not open './image/ring${RingNo}-files-absolute' for writing");

$FNFile  = *FN_FILE;
$CFNFile = *CFN_FILE;

foreach $CTLDir (@TLDirs)
{
        @CDirName = ('');
        ProcessDir ($CTLDir);
}

Shutdown ();






sub Shutdown
{
        close ($FNFile);
}



###################################
#
# Process a directory
#
# Param1: directory name (incl path)
#
sub ProcessDir
{
        my $DirName  = shift;
        my $Path     = $CDirName [-1];
        my @Files    = ();
        my $Filename;

#        print ("Opening '$KernelDir/$Path/$DirName'\n");
        opendir (DIR, "$KernelDir/$Path/$DirName")
                or return 0;
        @Files = readdir (DIR);
        closedir (DIR);

        SafeMkdir ("./image/$Path/$DirName");

        $Path = AddToPath ($Path, $DirName);
        push @CDirName, $Path;

        foreach $Filename (@Files)
        {
#                print ("  '$Filename'\n");
                if (($Filename eq '.') or ($Filename eq '..')) {
                        next;
                }
                if (-d "$KernelDir/$Path/$Filename") {
#                        print ("Found dir: '$Filename'\n");
                        ProcessDir ($Filename);
                }
                elsif ($Filename =~ /\.c$/) {
                        $Filename = AddToPath ($Path, "$Filename");
                        print ($FNFile  "$Filename\n");
                        print ($CFNFile "$KernelDir/$Filename\n");
                }
        }

        pop @CDirName;
}


###################################
#
# Create a directory (with some safety checks)
#
sub SafeMkdir
{
        my $Dirname = shift;

        if (! -d $Dirname)
        {
                if (-e $Dirname) {
                        die ("'$Dirname' already exists and is not a directory")
                }

                mkdir ($Dirname, 0755);
        }
}



sub AddToPath
{
        my $BasePath = shift;
        my $ToAdd    = shift;

        if (($BasePath eq '') or ($BasePath =~ m#/$#)) {
                return ($BasePath . $ToAdd);
        }
        else {
                return ($BasePath . '/' . $ToAdd);
        }
}

