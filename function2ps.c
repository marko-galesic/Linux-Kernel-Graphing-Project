
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <string.h>

#include "analyze_function.h"


/**
 * Read a line from stdin, strip EOL
 */
int GetLine (struct buffer_t *Buffer)
{
        size_t TextLen;

        if (fgets (Buffer->Ptr, Buffer->Size, stdin) == NULL) {
//                fprintf (stderr, "  fgets() failed\n");
                return 0;
        }

        TextLen = strlen (Buffer->Ptr);

        if (TextLen < 2) {
                fprintf (stderr, "  Token < 2 Bytes: %u '%s'\n",
                         strlen (Buffer->Ptr), Buffer->Ptr);
                return 0;
        }

        if (Buffer->Ptr [TextLen - 1] == '\n')
                Buffer->Ptr [TextLen - 1] = '\0';

        Buffer->ContentLen = TextLen;

        return 1;
}

/**
 * Initialize a new buffer
 */
void InitBuffer (struct buffer_t *Buffer, size_t Size)
{
        Buffer->Ptr        = malloc (Size);
        Buffer->Size       = Size;
        Buffer->ContentLen = 0;
}


/**
 * Reinitialize a buffer that already has been in use
 */
void ReinitBuffer (struct buffer_t *Buffer, size_t Size)
{
        if (Buffer->Size < Size)
        {
                free (Buffer->Ptr);
                Buffer->Ptr  = malloc (Size);
                Buffer->Size = Size;
        }

        Buffer->ContentLen = 0;
}


/**
 * Resize buffer by the specified number of bytes
 */
void ResizeBuffer (struct buffer_t *Buffer, size_t BytesToAdd)
{
        Buffer->Size += BytesToAdd;
        Buffer->Ptr = realloc(Buffer->Ptr, Buffer->Size);
}


/**
 * Destroy a buffer's contents
 */
void ClearBuffer (struct buffer_t *Buffer)
{
        free (Buffer->Ptr);
        Buffer->Ptr = 0;
        Buffer->Size = 0;
        Buffer->ContentLen = 0;
}


/**
 * Destroy a buffer object (assuming it was dynamically allocated)
 */
void DestroyBuffer (struct buffer_t *Buffer)
{
        ClearBuffer (Buffer);
        free (Buffer);
}


int WriteBuffer (const char *Filename, const struct buffer_t *Buffer)
{
        FILE *TheFile;

        TheFile = fopen (Filename, "w");
        if (TheFile == NULL)
                return 0;

        fwrite (Buffer->Ptr, 1, Buffer->ContentLen, TheFile);
        fclose (TheFile);

        return 1;
}


#if 0 // unneeded now
void Buf2BufCopy (struct buffer_t *Dest, const struct buffer_t *Src,
                  size_t StartPos, size_t Count)
{
        assert ((StartPos + Count) <= Src->Size);

        if (Count == 0)
                return;

        if ((Dest->Size - Dest->ContentLen) < Count)
        {
                ResizeBuffer (Dest, 2 * Count);
        }

        memcpy (Dest->Ptr + Dest->ContentLen,
                Src->Ptr + StartPos, Count);

        Dest->ContentLen += Count;
}
#endif


int ReadFunc (FILE *InFile, struct buffer_t *Buffer)
{
        int CharRead = fgetc (InFile);

        while (CharRead != '\0')
        {
                if (Buffer->ContentLen >= Buffer->Size) {
                        ResizeBuffer (Buffer, Buffer->Size);
                }

                Buffer->Ptr [Buffer->ContentLen] = CharRead;
                Buffer->ContentLen++;

                CharRead = fgetc (InFile);
        }

        return Buffer->ContentLen;
}


int main (void)
{
        struct buffer_t CFileName;    // current function file name
        struct buffer_t CFuncName;    // current function name
        struct buffer_t InputBuffer;  // <perl> -> AnalyzeFunction
        struct buffer_t TmpBuffer;    // AnalyzeFunction -> Data2PS
        struct buffer_t OutputBuffer; // Data2PS -> <file>

        /* (1) read function */

        InitBuffer (&CFileName,    2000);
        InitBuffer (&CFuncName,    2000);
        InitBuffer (&InputBuffer,  8000);
        InitBuffer (&TmpBuffer,     200);
        InitBuffer (&OutputBuffer, 8000);

        while (!feof (stdin))
        {
                ReinitBuffer (&CFileName,    2000);
                ReinitBuffer (&CFuncName,    2000);
                ReinitBuffer (&InputBuffer,  8000);
                ReinitBuffer (&TmpBuffer,     200);
                ReinitBuffer (&OutputBuffer, 8000);

                if (! GetLine (&CFileName)) {
                        continue;
                }

                if (! GetLine (&CFuncName)) {
                        continue;
                }

//                fprintf (stderr, "  Function name: %s\n", CFuncName.Ptr);
//                fprintf (stderr, "  File name: %s\n", CFileName.Ptr);

                ReadFunc (stdin, &InputBuffer);

//                fprintf (stderr, "  Size: %d Bytes\n", InputBuffer.ContentLen);

                analyze_function (&InputBuffer, &TmpBuffer);
                data2ps (CFuncName.Ptr, &TmpBuffer, &OutputBuffer);

//                fprintf (stderr, "Processed\n");

                if (! WriteBuffer (CFileName.Ptr, &OutputBuffer))
                {
                        return 0;
                }
        }


        ClearBuffer (&CFileName);
        ClearBuffer (&CFuncName);
        ClearBuffer (&TmpBuffer);
        ClearBuffer (&OutputBuffer);

        return 0;
}
