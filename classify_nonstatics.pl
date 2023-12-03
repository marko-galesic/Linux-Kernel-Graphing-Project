#!/usr/bin/perl -w
# Takes a kernel dir (cmdline) and a group of nonstatic functions (stdin),
# searches for them
#
# Actually reads a list of our encoded function-filenames from stdin


use strict;


my $KernelDir = $ARGV [0];

#  We eliminate strings, but eliminating comments is harder (do by
# hand).  Note this also catches EXPORT_SYMBOL as indirect (true, in a
# way).

my @FuncNames    = (); # List of function names to examine

# Key: function name; Value: list of tmp filenames (with encoded
# classification) containing that func
my %FileNames    = ();

my $i            = 0;  # Counter
my @StartLetters = (); # List of all first letters of the functions
my @TmpData      = (); #

# (almost) the complete kernel sources. Key: Source filename (with path)
# Value: array of that file's lines
my %KernelSrc    = ();

my $DetailedProgress = 1; # Shall we show detailed progress reports?



Progress ("  (1) Building function list ... ");
Init ();
my $FuncCount = @FuncNames;
Progress ("$FuncCount entries\n");

ReadKernel ();

my $SLetter = '';

foreach $SLetter (@StartLetters)
{
        @TmpData = ();
	GrepKernel ($SLetter);
}







##################################
#
# Print Progress message
#
# Param1: Message
#
sub Progress
{
	my $Message = shift;

	return unless ($DetailedProgress != 0);

        print (STDERR $Message);
}


####################################
#
# Read list of function-filenames from stdin and
# build the lists of functions, functionfiles and
# startletters from that
#
sub Init
{
	my $i;
	my %Seen       = ();
        my %LetterSeen = ();

        while (<STDIN>)
	{
                chomp;
		my $FileName = $_;
		my $FName    = $FileName;

		$FName =~ s/^.*\.c\.//;
		$FName =~ s/\.\+NONSTATIC\+.*$//;

		next if $FName =~ /^\s*$/;

		$Seen {$FName} = 1;  # to avoid dupes - the names are the keys
		$LetterSeen {substr ($FName, 0, 1)} = 1;

                AddFile ($FName, $FileName);
	}

	@FuncNames = sort (keys (%Seen));
        @StartLetters = sort (keys (%LetterSeen));
}



####################################
#
# Read and preprocess the kernel sources
#
sub ReadKernel
{
        my $RingNo;
        my @SrcFiles;
        my $CFile;

	Progress ("  (2) Reading, preprocessing kernel source ... ");

        for $RingNo (1..4)
        {
                @SrcFiles = GetSrcFileList ($RingNo);

                open (IN_FILTER, "../rmclutter <ring${RingNo}-files-absolute |")
                        or die ("could not launch input filter: !$\n");

                while (defined ($CFile = shift (@SrcFiles)))
                {
                        ReadSrcfile ($CFile, *IN_FILTER);
                }

                close (IN_FILTER);
        }

	my $SrcfileCount = scalar (keys (%KernelSrc));
	Progress ("$SrcfileCount files\n");
}


####################################
#
# Get list of kernel src files by reading ringX-files
#
# Param1: Ring number
#
sub GetSrcFileList
{
        my $RingNo = shift;
        my @Files;

        open (SRCLIST, "<ring${RingNo}-files")
                or die ("Could not read ring${RingNo}-files : $!\n");

        while (<SRCLIST>)
        {
                chomp;
                push @Files, $_;
        }

        return @Files;
}


##########################################
#
# Grep over the kernel source to grab all candidates
# for a given starting letter. Then Process the
# respective functions
#
# Param1: letter all functions have to start with
#
sub GrepKernel
{
        my $StartLetter = shift;
	my $Regex       = BuildRegex ($StartLetter);
	my @TheseFuncs  = grep (/^$StartLetter/, @FuncNames);
	my $FuncCount   = @TheseFuncs;
        my $SrcFile     = '';

	Progress ("  Analyzing Kernel Source ... ('$StartLetter': $FuncCount functions)\n");
#        Progress ("  Regex = '$Regex'\n");

	foreach $SrcFile (keys (%KernelSrc))
	{
		MatchFile ($SrcFile, $Regex);
	}

	my $CandidateCount = @TmpData;
	Progress ("    $CandidateCount interesting lines\n");

#	Progress ("    Processing Functions ... ('$StartLetter')\n");

	my $FuncName;

	foreach $FuncName (@TheseFuncs)
	{
		ProcessFunc ($FuncName);
	}
}


###########################################
#
# Add a function file to the list
#
# Param1: Function name (key)
# Param2: File name
#
sub AddFile
{
	my $FuncName = shift;
	my $FileName = shift;

	if (!defined ($FileNames {$FuncName})) {
		$FileNames {$FuncName} = ();
	}

	push (@{$FileNames {$FuncName}}, $FileName);

}


###########################################
#
# Build regular expression to find all occurences of the given
# functions in the kernel sources
#
# Param1: Letter all functions have to start with
#
sub BuildRegex
{
	my $StartLetter = shift;

	return  '(\b|\A)' . $StartLetter . '\w*\s*\(';
}



###########################################
#
# Read and preprocess a single file from the kernel sources
#
# Param1: File name
#
sub ReadSrcfile
{
        my $Filename = shift;
        my $InFilter = shift;

	$KernelSrc {$Filename} = ();

	while (readline ($InFilter))
        {
                return if ($_ eq "\0\n");

		# rmclutter already does most of the work
		s/(\b|\A)if\s*\(//;     # -> functions starting with 'i'
		s/(\b|\A)switch\s*\(//; # -> functions starting with 's'
		s/(\b|\A)while\s*\(//;  # -> functions starting with 'w'
		next unless /\(/;

		next if     /^\s*$/;

		push (@{$KernelSrc {$Filename}}, $_);
	}
}



#################################################
#
# Apply our big, multi-function-name regex to one file of
# the kernel sources
#
# Param1: Filename to examine
# Param2: The big regex
#
sub MatchFile
{
	my $Filename = shift;
	my $Regex    = shift;
        my $Line     = '';

	push @TmpData, grep (/$Regex/, @{$KernelSrc {$Filename}});
}





##############################################
#
# Try to see if function $1 is used indirectly in stdin.
#
# Returns a tring that is later analyzed for more hints
#
# Param1: Function name
#
sub AnalyzeUsage
{
	my $FuncName = shift;
        my $Code = '';

	# Eliminate strings, comments, compiler directives, occurances
	# followed by an optional space then '[A-Za-z0-9`'', occurances
	# preceeded by ->, lines starting with ' *', and finally real
	# function calls
	# FIXME: We can detect comment lines by occurrances of two
	# consecutive non-keywords without punctuation between them.

	#Progress ("    $FuncName : ");
	my @FuncLines = grep /$FuncName/, @TmpData;
        my $LineCount = @FuncLines;
	#Progress ("$LineCount occurences\n");

	foreach $_ (@FuncLines)
	{
		s/$FuncName *[A-Za-z0-9'\`]//;

		next if     (/$FuncName\s*\(/);
		next if     (/->\s*$FuncName/);
		next unless (/\b$FuncName\b/ || /^$FuncName/);

                $Code .= $_;
	}

        return $Code;
}



############################################
#
# Process (classify) one function
#
# Param1: Function name
#
sub ProcessFunc
{
        my $FuncName = shift;

	my $Code     = AnalyzeUsage ($FuncName);
	my $FileName = $FileNames {$FuncName};
        my $FuncType = '';

	if ($Code ne '')
	{
		if ($Code =~ /EXPORT_SYMBOL/)
		{
                        $FuncType = 'EXPORTED';
			#echo $f $NAME is EXPORTED: "`echo \"$FIND\"`"
		}
		else
		{
                        $FuncType = 'INDIRECT';
			#echo $f $NAME is INDIRECT: "`echo \"$FIND\"`"
		}
	}
	else
	{
                $FuncType = 'NORMAL';
	}

        ProcessFiles ($FuncName, $FuncType);
}



##########################################
#
# Apply a function classification by renaming the associated files
#
# Param1: Function name
# Param2: Classification (string)
#
sub ProcessFiles
{
	my $FuncName = shift;
	my $FuncType = shift;
        my $FileName;

	foreach $FileName (@{$FileNames {$FuncName}})
	{
		my $NewFName = $FileName;
		$NewFName =~ s/\+NONSTATIC\+/+$FuncType+/;
		rename ($FileName, $NewFName);
	}
}
