
#ifndef ANALYZE_FUNCTION_H
#define ANALYZE_FUNCTION_H


struct buffer_t
{
        char   *Ptr;
        size_t  Size;
        size_t  ContentLen;
};


/**
 * Initialize a new buffer
 */
void InitBuffer (struct buffer_t *Buffer, size_t Size);

/**
 * Reinitialize a buffer that already has been in use
 */
void ReinitBuffer (struct buffer_t *Buffer, size_t Size);

/**
 * Resize buffer by the specified number of bytes
 */
void ResizeBuffer (struct buffer_t *Buffer, size_t BytesToAdd);

/**
 * Destroy a buffer's contents
 */
void ClearBuffer (struct buffer_t *Buffer);

/**
 * Destroy a buffer object (assuming it was dynamically allocated)
 */
void DestroyBuffer (struct buffer_t *Buffer);



int analyze_function (const struct buffer_t *InputBuffer,
                            struct buffer_t *OutputBuffer);


int data2ps (const char *FunctionName,
             const struct buffer_t *InputBuffer,
                   struct buffer_t *OutputBuffer);

#endif
