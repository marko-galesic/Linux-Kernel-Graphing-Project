/* Takes a png, creates pngs XxY.png up to given arguments */
#include <limits.h>
#include <stdlib.h>
#include <png.h>

/* C trick to stringize a constant (expand to the number first) */
#define _STRINGIZE(x) #x
#define STRINGIZE(x) _STRINGIZE(x)

/* Useful macro which defines max size of a string containing an int.
   UINT has a U at the end, but int may have - at the front, so the
   size is correct. */
#define INT_CHARS (sizeof(STRINGIZE(UINT_MAX)))

static png_structp create_output(unsigned int x, unsigned int y,
				 unsigned int width, unsigned int height,
				 png_colorp palette,
				 png_uint_16 num_palette)
{
	png_structp png_ptr;
	png_infop info_ptr;
	char filename[INT_CHARS * 2 + sizeof("%ux%u.big.png")];
	FILE *f;

	sprintf(filename, "%06ux%06u.big.png", x, y);
	f = fopen(filename, "w");
	if (!f)
		return NULL;

	png_ptr = png_create_write_struct(PNG_LIBPNG_VER_STRING,
					  (png_voidp)NULL, NULL, NULL);
	if (!png_ptr)
		return NULL;

	info_ptr = png_create_info_struct(png_ptr);
	if (!info_ptr) {
		png_destroy_write_struct(&png_ptr, (png_infopp)NULL);
		return NULL;
	}

	if (setjmp(png_ptr->jmpbuf)) {
		png_destroy_write_struct(&png_ptr, &info_ptr);
		return NULL;
	}

	png_init_io(png_ptr, f);
	png_set_IHDR(png_ptr, info_ptr, width, height,
		     8, PNG_COLOR_TYPE_PALETTE, PNG_INTERLACE_NONE,
		     PNG_COMPRESSION_TYPE_DEFAULT, PNG_FILTER_TYPE_DEFAULT);
	png_set_PLTE(png_ptr, info_ptr, palette, num_palette);
	png_write_info(png_ptr, info_ptr);

	return png_ptr;
}

static void break_up(png_structp input,
		     png_infop info,
		     unsigned int num_cols, 
		     unsigned int num_rows)
{
	unsigned int x, y, i;
	png_structp output[num_cols][num_rows];
	png_bytep rowdata;
	png_colorp palette;
	int num_palette;
	unsigned int width, height;

	png_get_PLTE(input, info, &palette, &num_palette);
	/* Round down if neccessary */
	width = png_get_image_width(input, info)/num_cols;
	height = png_get_image_height(input, info)/num_rows;

	/* Open output files */
	for (x = 0; x < num_cols; x++) {
		for (y = 0; y < num_rows; y++) {
			output[x][y] = create_output(x, y,
						     width, height,
						     palette, num_palette);
		}
	}

	rowdata = malloc(png_get_image_width(input, info));
	for (i = 0; i < num_rows * height; i++) {
		png_read_row(input, rowdata, NULL);

		/* Which image does this belong to? */
		y = i / height;
		for (x = 0; x < num_cols; x++) {
			/* Write one line out to this image */
			png_write_row(output[x][y], rowdata + x * width);
		}
	}

	for (x = 0; x < num_cols; x++) {
		for (y = 0; y < num_rows; y++) {
			png_write_end(output[x][y], NULL);
		}
	}
}

/* input.png num-columns num-rows */
int main(int argc, char *argv[])
{
	FILE *fp;
	png_uint_32 width, height;
	int bit_depth, color_type;
	png_structp png_ptr;
	png_infop info_ptr;

	if (argc != 4) {
		fprintf(stderr,
			"Usage: split-image input.png num-columns num-rows\n");
		exit(1);
	}

	fp = fopen(argv[1], "r");
	if (!fp) {
		fprintf(stderr, "Can't open `%s'\n", argv[1]);
		exit(1);
	}
	png_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING,
					 (png_voidp)NULL,
					 NULL, NULL);

	info_ptr = png_create_info_struct(png_ptr);

	png_init_io(png_ptr, fp);
	png_read_info(png_ptr, info_ptr);
	png_get_IHDR(png_ptr, info_ptr, &width,
		     &height, &bit_depth, &color_type,
		     NULL, NULL, NULL);
	png_set_packing(png_ptr);

	break_up(png_ptr, info_ptr, atoi(argv[2]), atoi(argv[3]));
	return 0;
}
