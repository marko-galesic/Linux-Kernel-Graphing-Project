/*
 * Simple lex program to remove "clutter" (comments, string constants,
 * preprocessor directives) from C(++) code
 *
 * Strings are not completely removed, just "emptied" (to avoid falsifying
 * the PS output)
 *
 * Acts as filter (stdin to stdout)
 *
 * Author: Christian Reiniger <creinig@mayn.de>
 * $Id: rmclutter.lex,v 1.6 2002/07/17 18:05:33 creinig Exp $
 */

%option stack
%pointer


%x STRING
%x SSTRING
%x MCOMMENT
%x SCOMMENT
%x PPDIRECTIVE

%{

#include <stdio.h>
#include <assert.h>
#include <string.h>

//#undef YYLMAX
//#define YYLMAX 64000

//#define e(msg) fprintf (stderr, msg " (%d)\n%s\n\n", strlen (yytext), yytext)
#define e(msg)

%}


%%

<INITIAL>{
	"/*"           e("entering MC"); yy_push_state (MCOMMENT);
        "//"           yy_push_state (SCOMMENT);

	"\""           ECHO; yy_push_state (STRING);
        "'"            ECHO; yy_push_state (SSTRING);
        [[:space:]]+   {
                if (strchr (yytext, '\n') != NULL)
                        fprintf (yyout, "\n");
                else
                        fprintf (yyout, " ");
        }

	^#             yy_push_state (PPDIRECTIVE);
}



  /* Strings in double quotes */
<STRING>{
	\\.                                   /* escape sequence */
        \\\n                                  /* continue-line sequence */
	"\""           ECHO; yy_pop_state (); /* End of string */
        [^\\\"]+                              /* everything else */
}


  /* Strings in single quotes */
<SSTRING>{
	\\.                                   /* escape sequence */
        \\\n                                  /* continue-line sequence */
	"'"            ECHO; yy_pop_state (); /* End of string */
        [^\\\']+                              /* everything else */
}


  /* Multiline comment */
<MCOMMENT>{

        [^*/]+         e("MC: normal text");   /* normal text */

                       /* Nested multiline comment */
        "/*"           e("MC: nested"); yy_push_state (MCOMMENT);

        "*/"           e("MC: end");    yy_pop_state ();/* end-of-comment */

        "*"            e("MC: asterisk");      /* normal asterisk */
        "/"            e("MC: slash");         /* normal slash    */
}


  /* Single line comment */
<SCOMMENT>{

	[^\n]+                        /* normal text */
	\n           yy_pop_state (); /* end-of-comment */
}


  /* Preprocessor directive */
<PPDIRECTIVE>{
        "/*"         yy_push_state (MCOMMENT); /* [1] */
        "//"         yy_push_state (SCOMMENT); /* [2] */
	[^\\\n]                       /* eat it up */
        \\\n                          /* continue-line char */
        \n           yy_pop_state (); /* end of directive */
        .                             /* eat what remains */

        /* [1] : For multiline comments starting on the same line as the
                 PP directive and extending beyond it. Nobody should do
                 this, but it's legal and it *does* occur */
        /* [2] : Just to be prepared for truly *evil* code like
                 #if 0  // deprecated \* Start of an old comment
         */
}



%%




void InitScanner (FILE *InStream)
{
        yyout = stdout;
        BEGIN(INITIAL);
        yyrestart (InStream);
}


/**
 * Process a stream, writing to stdout
 *
 * Can be called repeatedly.
 */
void RmClutter (FILE *InStream)
{
        InitScanner (InStream);
//        fprintf (stderr, "  Initialized Scanner\n");
        yylex ();
}


/**
 * Read name of file to be processed from stdin
 */
const char *GetFilename ()
{
        static char Buffer [6000];
        size_t      TextLen;

        if (fgets (Buffer, 6000, stdin) == NULL)
                return NULL;

        TextLen = strlen (Buffer);
        assert (TextLen < 6000);

        if (TextLen < 2)
                return NULL;

        if (Buffer [TextLen - 1] == '\n')
                Buffer [TextLen - 1] = '\0';

        return Buffer;
}


/**
 * Process Size bytes from InFile, writing the results to OutFile
 */
void ProcessFile (const char *Filename)
{
        FILE *InFile = 0;

//        fprintf (stderr, "Processing '%s'\n", Filename);
        if ((InFile = fopen (Filename, "r")) == NULL) {
                fprintf (stderr, "Failed opening '%s' for reading: ", Filename);
                perror ("");
                fprintf (stderr, "\n");
                return;
        }

//        fprintf (stderr, "  File '%s' opened\n", Filename);
        RmClutter (InFile);
        fputc ('\0', stdout);
        fputc ('\n', stdout);

        fclose (InFile);
}


int main(void)
{
        const char *InputFile = 0;

        while ((InputFile = GetFilename ()) != NULL)
        {
                ProcessFile (InputFile);
        }

	return 0;
}

