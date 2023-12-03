/* Takes output of analyze_function.sh as parameters and produces
   PostScript for a single function. */
#include <unistd.h>
#include <math.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

#include "analyze_function.h"

#define MAXSIZE 1000
#define LINE_LENGTH 5
#define MAX_VARIANCE 6
#define FORK_MINVAR 20
#define FORK_MAXVAR 120

#define DEG2RAD(d) ((d)/180.0 * M_PI)

#define DIST(x,y) sqrt((double)(x) * (x) + (double)(y) * (y))

struct coord
{
	float x;
	float y;
};

struct bounding_box
{
	struct coord min, max;
};

struct context
{
	struct coord last_end;
        struct bounding_box bound;

        /* buffer containing input, NUL terminated */
        const struct buffer_t *in_buf;
        size_t                 input_pos;

	/* buffer containing output, NUL terminated. */
	struct buffer_t       *out_buf;
};


static unsigned int d2p_iterate(struct context *c,
                                struct coord *here,
                                float *angle,
                                unsigned int depth,
                                int do_loop);







static void d2p_update_boundingbox(struct bounding_box *bound, struct coord c)
{
	if (c.x < bound->min.x) bound->min.x = c.x;
	if (c.y < bound->min.y) bound->min.y = c.y;
	if (c.x > bound->max.x) bound->max.x = c.x;
	if (c.y > bound->max.y) bound->max.y = c.y;
}

static void d2p_combine_boundingboxes(struct bounding_box *bound,
                                      struct bounding_box oldbound)
{
	/* This is overkill, but easy */
	d2p_update_boundingbox(bound, oldbound.min);
	d2p_update_boundingbox(bound, oldbound.max);
}

static void d2p_dump(struct context *context)
{
	fputs(context->out_buf->Ptr, stdout);
}

static void d2p_print(struct context *Context, char *fmt, ...)
{
        char *p;
        int   RetVal;
	va_list ap;
        size_t size = Context->out_buf->ContentLen;

//        fprintf (stderr, "    d2p_print: format %s\n", fmt);
	p = Context->out_buf->Ptr + size;
	va_start(ap, fmt);

        RetVal = vsnprintf(p, Context->out_buf->Size - size, fmt, ap);
        while ((RetVal >= Context->out_buf->Size - size - 1) || (RetVal == -1))
        {
                ResizeBuffer (Context->out_buf, Context->out_buf->Size);
		p = Context->out_buf->Ptr + size;

                RetVal = vsnprintf(p, Context->out_buf->Size - size, fmt, ap);
        }

//        fprintf (stderr, "    d2p_print: %d bytes (%s)\n", RetVal, Context->output_buffer + size);
        Context->out_buf->ContentLen += RetVal;
        va_end(ap);
}


#ifdef DEBUG
#  define d2p_debug2ps(c, f) d2p_print(c, f)
#else
#  define d2p_debug2ps(c, f)
#endif


static char *d2p_coord2string (char *dest, float coord)
{
        int i;

        if ((coord >= 100) || (coord <= -100)) {
                sprintf (dest, "%d", (int) coord);
        }
        else if ((coord >= 10) || (coord <= -10)) {
                sprintf (dest, "%.1f", coord);
        }
        else {
                sprintf (dest, "%.2f", coord);

		/* cut trailing 0 */
                i = strlen (dest) - 1;
                if (dest [i] == '0')
                        dest [i] = '\0';
        }

        /* cut .0 fraction */
        i = strlen (dest) - 2;
        if ((dest [i+1] == '0') && (dest [i] == '.'))
                dest [i] = '\0';

        return dest;
}


static void d2p_lineto (struct context *Context, float coord_x, float coord_y)
{
        static char XBuffer [15];
        static char YBuffer [15];

        d2p_coord2string (XBuffer, coord_x);
        d2p_coord2string (YBuffer, coord_y);

        if (Context == 0)
                printf ("%s %s L\n", XBuffer, YBuffer);
        else
                d2p_print (Context, "%s %s L\n", XBuffer, YBuffer);
}


static void d2p_moveto (struct context *Context, float coord_x, float coord_y)
{
        static char XBuffer [15];
        static char YBuffer [15];

        d2p_coord2string (XBuffer, coord_x);
        d2p_coord2string (YBuffer, coord_y);

        if (Context == 0)
                printf ("%s %s M\n", XBuffer, YBuffer);
        else
                d2p_print (Context, "%s %s M\n", XBuffer, YBuffer);
}


static struct coord d2p_draw_line(unsigned len,
                                  int complexity,
                                  float angle,
                                  struct coord from,
                                  struct context *context)
{
	struct coord to;

	/* Do we need to move? */
	if (from.x != context->last_end.x || from.y != context->last_end.y) {
		d2p_moveto (context, from.x, from.y);
		d2p_update_boundingbox(&context->bound, from);
	}

	to.x = cos(DEG2RAD(angle))*len + from.x;
	to.y = sin(DEG2RAD(angle))*len + from.y;

	/* Draw line */
	d2p_lineto (context, to.x, to.y);

	/* Update context */
	context->last_end.x = to.x;
	context->last_end.y = to.y;

	/* Draw hair */
	if (complexity > random() % 50) {
		int left = random()%2;
		float hairangle = angle + (left ? 60 : -60);

		d2p_debug2ps(context, "%% hair!\n");
		d2p_draw_line(3, 0, hairangle, to, context);
	}

	/* Update bounding box */
	d2p_update_boundingbox(&context->bound, to);
	return to;
}

static unsigned d2p_loop(struct context *c,
		     struct coord *here,
		     float *angle,
		     int do_loop)
{
	/* Start new bounding box: we want to draw
	   circle around it */
	struct bounding_box old_bound;
	unsigned int advancedness;
	float radius;

	old_bound = c->bound;
	c->bound.min.x = c->bound.max.x = here->x;
	c->bound.min.y = c->bound.max.y = here->y;

	advancedness = d2p_iterate(c, here, angle, 0, do_loop);

	/* Draw a circle approx. around range covered. */
	radius = DIST(c->bound.max.x - c->bound.min.x,
		      c->bound.max.y - c->bound.min.y)/2.3;

        d2p_print(c, "%.2f %.2f %.2f A\n",
                  (c->bound.max.x + c->bound.min.x)/2,
                  (c->bound.max.y + c->bound.min.y)/2,
                  radius);

	/* Update bounding box */
	d2p_combine_boundingboxes(&c->bound, old_bound);
	return advancedness;
}

static unsigned int d2p_iterate(struct context *c,
                                struct coord *here,
                                float *angle,
                                unsigned int depth,
                                int do_loop)
{
        const char *arg;
	unsigned int advancedness = 0;
        unsigned int dot_count    = 0;

	while (c->input_pos < c->in_buf->ContentLen)
        {
                arg = c->in_buf->Ptr + c->input_pos;
//                fprintf (stderr, "    IB: %p, IS: %d, IP: %d, arg: %p\n", c->input_buffer, c->input_size, c->input_pos, arg);

                /* a series of dots has ended -> flush line */
		if ((dot_count != 0) && (arg [0] != '.'))
		{
			*here = d2p_draw_line(dot_count, advancedness,
                                              *angle, *here, c);
			dot_count = 0;
		}

                if (strncmp(arg, "i(", 2) == 0)
                {
                        /* FIXME: Control angle by weight of different branches */
			/* Branch */
			unsigned int fork_margin
				= random()%(FORK_MAXVAR/2) + FORK_MINVAR/2;
			float newangle;
			struct coord new = *here;

//                        fprintf (stderr, "    i(\n");
                        c->input_pos += 2;

			d2p_debug2ps(c, "%% If starts here\n");
			newangle = *angle + fork_margin;
			while (newangle > 360) newangle -= 360;
			advancedness += d2p_iterate(c, &new, &newangle, 0, 0);
			*angle -= fork_margin;
			while (newangle < 0) newangle += 360;
			d2p_debug2ps(c, "%% If ends here\n");
                }
                else if (strncmp(arg, "d(", 2) == 0)
                {
//                        fprintf (stderr, "    d(\n");
                        c->input_pos += 2;
			d2p_debug2ps(c, "%% do loop start\n");
			advancedness += d2p_loop(c, here, angle, 1);
			d2p_debug2ps(c, "%% do loop end\n");
                }
                else if (strncmp(arg, "f(", 2) == 0)
                {
//                        fprintf (stderr, "    f(2\n");
                        c->input_pos += 2;
			d2p_debug2ps(c, "%% for loop start\n");
			advancedness += d2p_loop(c, here, angle, 0);
			d2p_debug2ps(c, "%% for loop end\n");
                }
                else
                {
                        c->input_pos += 1;
//                        fprintf (stderr, "    '%d'\n", *arg);

			switch (arg[0]) {
			case 'w':
				/* while */
				if (depth == 0 && do_loop) {
					d2p_debug2ps(c, "%% do loop end detected\n");
					goto out;
				}
				d2p_debug2ps(c, "%% while loop start\n");
				advancedness += d2p_loop(c, here, angle, 0);
				d2p_debug2ps(c, "%% while loop end\n");
				break;

                        case '.':
				/* Statement */
                                dot_count++;
				break;

			case ';':
				/* End of loop / if */
				if (depth == 0)
					goto out;
				break;

			case '{':
				depth++;
				break;

			case '}':
				depth--;
				/* End of loop / if block */
				if (depth == 0 && !do_loop)
					goto out;
				break;

			case '!':
				advancedness++;
				break;

			default:
				fprintf(stderr, "Unexpected argument '%s' @ %d\n",
					arg, c->input_pos - 1);
				exit(1);
			}

			if (dot_count == 0) {
				*here = d2p_draw_line(1, advancedness,
                                                      *angle, *here, c);
			}
		}

                *angle += random()%MAX_VARIANCE-MAX_VARIANCE/2;
		if (*angle < 0)        *angle += 360;
		else if (*angle > 360) *angle -= 360;
	}
 out:
	return advancedness;
}

static void d2p_init_context(struct context *c, struct coord start,
                             const struct buffer_t *InputBuffer,
                                   struct buffer_t *OutputBuffer)
{
	c->bound.min.x = c->bound.max.x = 0;
	c->bound.min.y = c->bound.max.y = 0;
	c->last_end.x  = start.x;
        c->last_end.y  = start.y;

	c->out_buf     = OutputBuffer;
        c->in_buf      = InputBuffer;
        c->input_pos   = 0;

//        fprintf (stderr, "    d2p: context initialized (input size %d)\n", c->input_size);
	d2p_moveto (c, c->last_end.x, c->last_end.y);
}


int data2ps (const char            *FunctionName,
             const struct buffer_t *InputBuffer,
                   struct buffer_t *OutputBuffer)
{
	struct context c;
	struct coord start = { 0, 0 };
	unsigned int i, total = 0;
	float angle = 0;

	/* Sum function name to get seed. */
	for (i = 0; i < strlen(FunctionName); i++) total += i;
	srandom(total);

        d2p_init_context(&c, start, InputBuffer, OutputBuffer);
	d2p_iterate(&c, &start, &angle, 1, 0);
//        fprintf (stderr, "    d2p: processed. Output size: %d\n", c.output_pos);

	/* Finish it */
	d2p_print(&c, "S\n");
	/* Never want zero width or height; pad by 1 */
	d2p_print(&c, "%% Bound %.2f %.2f %.2f %.2f\n",
                  c.bound.min.x-1, c.bound.min.y-1, c.bound.max.x+1, c.bound.max.y+1);

	return OutputBuffer->ContentLen;
}


#if 0
/* Reads standard input for data stream.   Args: function name. */
int main(int argc, const char *argv[])
{
	struct context c;
	struct coord start = { 0, 0 };
	unsigned int i, total = 0;
	float angle = 0;

	/* Sum function name to get seed. */
	for (i = 0; i < strlen(argv[1]); i++) total += i;
	srandom(total);

	d2p_init_context(&c, start);
	d2p_iterate(&c, &start, &angle, 1, 0);

	/* Finish it */
	d2p_dump(&c);
	printf("0 0 moveto stroke\n");
	/* Never want zero width or height; pad by 1 */
	printf("%% Bound %.2f %.2f %.2f %.2f\n",
	       c.bound.min.x-1, c.bound.min.y-1, c.bound.max.x+1, c.bound.max.y+1);

	return 0;
}
#endif

