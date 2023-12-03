/* Simple lex program to analyze function. */

%option pointer
%pointer

ALNUM      [a-zA-Z0-9_]*
SPACE      [[:blank:]\f\n]

%{

#include <string.h>
#include <stdlib.h>

#include "analyze_function.h"

#undef YYLMAX
#define YYLMAX 64000

const struct buffer_t *af_inbuf;
struct buffer_t       *af_outbuf;
size_t                 af_inbuf_pos;

/* copy data from input buffer to flex buffer. Requires pointer to input
 * buffer to be present as global var buffer_t *af_inbuf and a global
 * int af_inbuf_pos for storage of the current position in the input buffer
 */
#define YY_INPUT(buf,result,max_size) \
{ \
        int yyiCopySize = af_inbuf->Size - af_inbuf_pos; \
        if (max_size < yyiCopySize) \
                yyiCopySize = max_size; \
        if (yyiCopySize > 0) \
                memcpy (buf, af_inbuf->Ptr + af_inbuf_pos, yyiCopySize); \
        af_inbuf_pos += yyiCopySize; \
        result = yyiCopySize; \
}




void afPrint (const char *Sym)
{
        size_t SLen = strlen (Sym);
        while ((af_outbuf->Size - af_outbuf->ContentLen) < SLen) {
                af_outbuf->Size *= 2;
                af_outbuf->Ptr = realloc (af_outbuf->Ptr, af_outbuf->Size);
        }

        memcpy (af_outbuf->Ptr + af_outbuf->ContentLen, Sym, SLen);
        af_outbuf->ContentLen += SLen;

/*        fprintf (stderr, "    afPrint: %d bytes ('%s')\n", SLen, Sym); */
}

%}

%%

#.*\n

{SPACE}+

"if"        afPrint("i(");

"//"        {	      register int c;
		      while ( (c = input()) != '\n' && c != EOF);
		      afPrint(".");
                }


"/*"        {
                      register int c;

                      for ( ; ; )
                          {
                          while ( (c = input()) != '*' &&
                                  c != EOF )
                              ;    /* eat up text of comment */

                          if ( c == '*' )
                              {
                              while ( (c = input()) == '*' )
                                  ;
                              if ( c == '/' )
                                  break;    /* found the end */
                              }

                          if ( c == EOF )
                              {
                              fprintf(stderr, "EOF in comment\n" );
                              break;
                              }
                          }
		}

\"              {
                      register int c;

                      while ((c = input()) != '"' && c != EOF) {
			      if (c == '\\') {
				      if (input() == EOF) {
					      fprintf(stderr,
						      "EOF in string\n");
					      break;
				      }
			      }
		      }
		      afPrint(".");
                }

\'              {
                      register int c;

                      while ((c = input()) != '\'' && c != EOF) {
			      if (c == '\\') {
				      if (input() == EOF) {
					      fprintf(stderr,
						      "EOF in string\n");
					      break;
				      }
			      }
		      }
		      afPrint(".");
                }

for	afPrint("f(");

do	afPrint("d(");

while	afPrint("w");

 /* Union, attribute worth 1. */
union|attribute|__attribute__              afPrint("!");

 /* goto, inline worth 2 */
inline|__inline__|goto              afPrint("!!");

 /* register, mb, FASTCALL worth 4 */
register|"mb()"|FASTCALL        afPrint("!!!!");

 /* asm worth 8 */
asm              afPrint("!!!!!!!!");

 /* Hack for some crap #if 0'd stuff in arch/alpha/kernel/smc37c669.c. */
"$"

{ALNUM}+        afPrint(".");

"("|")"         afPrint(".");

";"             afPrint(";");

\\\n

"<<"|">>"|"=="|"!="|"||"|"&&"|"|="|"&="|"^="|"<<="|">>=" afPrint(".");

"<"|">"|"="|"!"|"|"|"&"|"^"|"~"|"["|"]"|","|"+"|"-"|"*"|"/"|"%"|"." afPrint(".");

"?"            afPrint("i({");

":"            afPrint("}");

"{"            afPrint("{");

"}"            afPrint("}");

%%


/*
 * analyze function and generate "intermediate code" from it.
 * Both *InputBuffer and *OutputBuffer have to be initialized,
 * allocated (Size > 0) and freed by the caller
 *
 * Returns number of bytes in output buffer
 */
int analyze_function (const struct buffer_t *InputBuffer, struct buffer_t *OutputBuffer)
{
        af_outbuf    = OutputBuffer;
        af_inbuf     = InputBuffer;
        af_inbuf_pos = 0;

        yylex ();

//        fprintf (stderr, "    af: Done lexing\n");
        /* add terminating NUL */
        if ((af_outbuf->Size - af_outbuf->ContentLen) < 1) {
                af_outbuf->Size *= 2;
                af_outbuf->Ptr = realloc (af_outbuf->Ptr, af_outbuf->Size);
        }
        af_outbuf->Ptr [af_outbuf->ContentLen] = '\0';
//        fprintf (stderr, "    af: NUL appended\n");

        return af_outbuf->ContentLen;
}

