#!/usr/bin/perl -w

# FIXME: handle FASTCALL (eg mm/filemap.c's truncate_list_pages).

use strict;

my $MinFuncSize = shift @ARGV; # minimum number of lines for a function to
                               # be processed
my $RingNo      = shift @ARGV; # Ring number to process (1..4)
my @SrcFiles    = ();
my $DestDir     = "image";     # destination dir
my $InputFilter;               # stream from input filter process
my $OutputFilter;              # stream to output filter process

# Variables used during processing
my $CFileName;   # name of the current file
my @CFile;       # Current source file as array of lines
my @CFunc;       # Current function as array of lines



@SrcFiles = GetFiles ();

open (IN_FILTER, "./rmclutter <image/ring${RingNo}-files-absolute |")
        or die ("Could not launch input filter (rmclutter): $!\n");
$InputFilter = *IN_FILTER;

open (OUT_FILTER, "| ./function2ps")
#open (OUT_FILTER, ">ring${RingNo}-functions")
        or die ("Could not launch output filter (function2ps): $!\n");
$OutputFilter = *OUT_FILTER;

while (ProcessFile () != 0)
{}

close (IN_FILTER);
close (OUT_FILTER);

#my $SrcFile     = $ARGV [1]; # Filename of the source file
#my @CurrentFunc = ();        # Lines of the current function
#my $funcname    = '';        # Name of the current function
#my $i           = 0;         # Counter



sub ProcessFile
{
        my $CFuncName;   # name of the current function
        my $FCount = 0;  # number of found functions

        $CFileName = shift (@SrcFiles);
        return 0 unless (defined ($CFileName));

        @CFile     = ReadFile ();

        print "Finding functions in $CFileName (" . scalar @CFile . " lines)";
        my $i = 0;

        while (($i < @CFile) && ($i >= 0))
        {
                ($i, $CFuncName) = FindFunction ($i);

                if ($i < 0) # no more functions
                {
                        print "... $FCount\n";
                        return (1);
                }

                $FCount++;
                $i = ReadFunc ($i);

                HandleFunc ($CFuncName);
        }

        print " ... $FCount\n";
        return 1;
}



sub GetFiles
{
        my @Files = ();
        my $FName = "${DestDir}/ring${RingNo}-files";

        open (FILELIST, "<$FName")
                or die ("Could not open file list '$FName' for reading: $!\n");

        while (<FILELIST>)
        {
                chomp;
                push @Files, $_;
        }

        close (FILELIST);

        return @Files;
}



####################################
#
# Read the input file from the Input Filter
#
sub ReadFile
{
        my @Lines = ();

        while ($_ = readline ($InputFilter))
        {
                if ($_ eq "\0\n") {
                        return @Lines;
                }

                push @Lines, $_;
        }
}


#####################################
#
# Find the starting line of the next function
#
# Param1:  Line number to start searching at
# Returns: list (Line number where the function starts, function name);
#          line number is -1 on failure
#
sub FindFunction
{
	my $StartAt   = shift;
        my $i         = $StartAt;
	my $Funcname  = "";  # Function Name
        my $OpenBrace = 0;   # Line number of the opening brace

	# Find opening brace
	while ($CFile[$i] !~ /^\{\s*$/)
	{
		++$i;

		if ($i >= @CFile) {
			return (-1, '');
		}
	}

        $OpenBrace = $i;

	# Search back for first line with open bracket.
	while ($CFile[$i] !~ /^\w.*\w\s*\(/)
	{
		--$i;

		if ($i < 0) {
			return (-1, '');
		}
	}

	if ($i < $StartAt) {
		# that's no real function we found - a struct or so.
		# restart scanning after the opening brace
		return FindFunction ($OpenBrace + 1);
	}

	# extract function name
	$Funcname = $CFile[$i];
	chomp($Funcname);
	$Funcname =~ s/^.*?(\w+)\s*\(.*$/$1/;

	if ($Funcname !~ /^\w+$/)
	{
                warn ("invalid function name: '$Funcname'");
		return (-1, '');
	}

#	print "Found function '$Funcname'\n";

	# Search back to first line not belonging to the function
        while (($i >= 0) && ($CFile[$i] =~ /^[A-Za-z_]/) && ($CFile[$i] !~ /;/))
	{
		$i--;
	}

	# and skip it.
	$i++;

        return ($i, $Funcname);
}




################################
#
# Read a function into memory
#
# Param1:  Line number to start at
# Returns: Line number after the function
#
sub ReadFunc
{
	my $StartAt  = shift;
        my $i        = 0;

        @CFunc = ();

	for ($i = $StartAt ; $i < @CFile ; ++$i)
	{
		my $CLine = $CFile[$i];

		push @CFunc, $CLine;

		if ($CLine =~ /^\}\s*$/) {
                        return $i + 1;
		}
	}

        return $i;
}



#####################################
#
# Check whether a function is declared as static
# Used global array @CurrentFunc
#
# Returns: true if static, false otherwise
#
sub IsStatic
{
	foreach $_ (@CFunc)
	{
		last if     (/^\s*{/);
                next unless (/static/);
		next if     (/\wstatic/);
		next if     (/static\w/);

                return 1;
	}

        return 0;
}


########################################
#
# Try to see whether a function is used indirectly in its source file
#
# Param 1: Function Name
#
# Returns: true if used indirectly, false otherwise
#
sub used_indirectly
{
	my $FuncName = shift;

	# Eliminate strings, comments, lines starting with *, occurances
	# followed by an optional space then '[A-Za-z0-9`'', and finally
	# real function calls

        my $Line;
	foreach $Line (grep (/$FuncName/, @CFile))
	{
		$_ = $Line;

#		s#/\*[^*]*$##;
		s/$FuncName *[\w'\`]//;

		next if     (/$FuncName\s*\(/);
		next unless (/\b$FuncName\b/ || /^$FuncName/);

                return 1;
	}

        return 0;
}



########################################
#
# Write the current function to a file,
# encoding the classification into the filename
#
# Param1: Function name
# Param2: Classification (string)
#
sub WriteFunc
{
        my $FuncName = shift;
	my $Class    = shift;
	my $Filename = "$DestDir/$CFileName" . ".${FuncName}.+${Class}+.ps";
        my $Line     = '';

        print ($OutputFilter "$Filename\n");
        print ($OutputFilter "$FuncName\n");
	foreach $Line (@CFunc)
        {
                $Line =~ s/\0/ /g;
                print ($OutputFilter $Line);
        }

        # Just \0 as delimiter - makes it easier for function2ps
        print ($OutputFilter "\0");
}



########################################
#
# Process the current function (classify & write)
#
# Param1: Function name
#
sub HandleFunc
{
	my $FuncName = shift;

	if ($FuncName eq '') {
		return;
	}

	# check for minimum size
	if (@CFunc < $MinFuncSize) {
		return;
	}

	if (not IsStatic ())
	{
		# Have to search entire kernel tree for references,
		# so we do this later.
                WriteFunc ($FuncName, "NONSTATIC");
	}
	else
	{
		if (used_indirectly ($FuncName))
		{
			# # Report if it's not the most common cases: = foo or foo,
			# if [ -z "`used_indirectly $NAME < $FILE | grep =\ \*$NAME`" \
			#     -a -z "`used_indirectly $NAME < $FILE | grep $NAME\ \*,`" ]
			# then
			#     echo -n $1 $NAME is STATIC INDIRECT:
			#     used_indirectly $NAME < $FILE
			# fi
                        WriteFunc ($FuncName, "INDIRECT");
		}
		else
		{
                        WriteFunc ($FuncName, "STATIC");
		}
	}
}
