/* Takes a set of ps files, and places them in a sector.  Produces a ps */
#include <math.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>

#define DEG2RAD(d) ((d)/180.0 * M_PI)

struct coord
{
	float x;
	float y;
};

struct bounding_box
{
	struct coord min, max;
};

static float draw_images(const char *argv[],
			 unsigned order[],
			 float startangle,
			 float ang[],
			 float dist[],
			 struct bounding_box bound[])
{
	unsigned int i;
	float x,y;
	float max_radius = 0;

	for (i = 0; argv[i]; i++) {
		int bytes;
		char buffer[32768];
		int fd = open(argv[order[i]], O_RDONLY);
		float height, width;

		if (fd < 0) {
			fprintf(stderr, "Can't read %s\n", argv[order[i]]);
			exit(1);
		}

		x = cos(DEG2RAD(startangle + ang[order[i]])) * dist[order[i]];
		y = -sin(DEG2RAD(startangle + ang[order[i]])) * dist[order[i]];

                /* Translate so *center* is at desired x,y pos */
#ifdef DEBUG
		printf("%% Centering %s on %.2f %.2f (ang %.2f, rad %.2f)\n",
                       argv[order[i]], x, y, ang[order[i]], dist[order[i]]);
#endif
                printf("%.2f %.2f T\n",
		       x - (bound[order[i]].min.x + bound[order[i]].max.x)/2,
		       y - (bound[order[i]].min.y + bound[order[i]].max.y)/2);
		fflush(stdout);

		width = bound[order[i]].max.x - bound[order[i]].min.x;
		height = bound[order[i]].max.y - bound[order[i]].min.y;

		/* Worst case is diagonal = sqrt(width^2 + height^2)/2,
		   but we want a bit of padding, so say 0.8 */
		if (dist[order[i]] + width*0.8 > max_radius)
			max_radius = dist[order[i]] + width*0.8;
		if (dist[order[i]] + height*0.8 > max_radius)
			max_radius = dist[order[i]] + height*0.8;

		while ((bytes = read(fd, buffer, sizeof(buffer))) > 0) {
			if (write(STDOUT_FILENO, buffer, bytes) != bytes) {
				fprintf(stderr,
					"Error writing %s output: %s\n",
					argv[order[i]], strerror(errno));
			exit(1);
			}
		}
		if (bytes < 0) {
			fprintf(stderr,
				"Error reading %s: %s\n",
				argv[order[i]], strerror(errno));
			exit(1);
		}
		close(fd);
                printf("R\n");
	}
	return max_radius;
}

#define MAX_IMAGES 5000
/* scrunchfactor minangle angle minradius small_row_scrunch small_row_max*/
int main(int argc, const char *argv[])
{
	double scrunch_factor = atof(argv[1]);
	double startangle = atof(argv[2]);
	double total_angle = atof(argv[3]);
	double minradius, init_minradius = atof(argv[4]);
    double small_row_scrunch = atof(argv[5]);
    int small_row_max = atoi(argv[6]);
	struct bounding_box bound[MAX_IMAGES];
	float dist[MAX_IMAGES], ang[MAX_IMAGES];
	float angle, largest_radius;
    /*for testing if a small row can be scrunched (if it comes to that)*/
    float angle_scrunch, angscrunch[MAX_IMAGES];
    int didscrunch;
	unsigned int order[MAX_IMAGES];
	unsigned int i, j, first_in_this_ring;
	double radius_scrunch = scrunch_factor;

	/* Eliminate progname and args */
	argv += 7;
	argc -= 7;

	if (argc > MAX_IMAGES) {
		fprintf(stderr, "TOO MANY IMAGES: %u\n", argc);
		exit(1);
	}
	/* Read the sizes of the files. */
	for (i = 0; i < argc; i++) {
		FILE *fp;
		char command[1024];

		sprintf(command, "tail -n 1 %s", argv[i]);
		fp = popen(command, "r");
		if (fscanf(fp, "%% bound %f %f %f %f",
			   &bound[i].min.x, &bound[i].min.y,
			   &bound[i].max.x, &bound[i].max.y) != 4) {
			fprintf(stderr, "Error reading %s\n", argv[i]);
			exit(1);
		}
		pclose(fp);
	}

	for (i = 0; i < argc; i++)
		order[i] = i;

	/* Order them from smallest diagonal length to largest. */
	for (i = 0; i < argc; i++) {
		unsigned int j;

#define HEIGHT(n) (bound[n].max.y-bound[n].min.y)
#define WIDTH(n) (bound[n].max.x-bound[n].min.x)
#define DIAMETER(n) sqrt(HEIGHT(n)*WIDTH(n))

		for (j = i; j < argc; j++) {
			if (DIAMETER(order[j]) < DIAMETER(order[i])) {
				unsigned int tmp;
				tmp = order[i];
				order[i] = order[j];
				order[j] = tmp;
			}
		}
	}

	if (init_minradius == 0) {
		/* Special case, put largest in the middle. */
		dist[order[argc-1]] = 0;
		ang[order[argc-1]] = 0;
		init_minradius = DIAMETER(order[argc-1])/2;
		argc--;
	}

 again:
	largest_radius = 0;
	minradius = init_minradius;
	/* Put each one in its place */
	angle = 0;
    angle_scrunch = 0;
    didscrunch = 0;
	first_in_this_ring = 0;
	for (i = 0; i < argc;) {
		float radius, degrees;
        /*for testing if a small row can be scrunched (if it comes to that)*/
        float degrees_scrunch;
        int doscrunch = 0;
		/* Radius for our center */
		radius = minradius + DIAMETER(order[i])/2;

		/* This is always true, but here in case we decide to
                   do largest to smallest. */
		if (DIAMETER(order[i])/2 > largest_radius)
			largest_radius = DIAMETER(order[i])/2;

		/* At this radius, how many degrees do we use? */
		degrees = DIAMETER(order[i]) / (radius * 2 * M_PI) * 360
			* scrunch_factor;
		degrees_scrunch = DIAMETER(order[i]) / (radius * 2 * M_PI) * 360
			* small_row_scrunch;

		/* Can't fit?  Enlarge radius and try again. */
		/* NOTE: don't enlarge radious if i is already the only member
		    of the ring.  Also, don't enlage if row is small and can
            be scrunched to fit*/
		if (angle + degrees > total_angle && i > first_in_this_ring) {
            if (angle_scrunch + degrees_scrunch <= total_angle && 
                    i - first_in_this_ring < small_row_max) {
                doscrunch = 1;
                didscrunch = 1;
            }
            else {
                /* Cool, lets stretch out this ring to use whole angle */
                /* FIXME: make this random, to avoid lines */
                for (j = first_in_this_ring; j < i; j++)
                    ang[order[j]] *= total_angle/angle;

                /* And go to next ring */
                first_in_this_ring = i;
                angle = 0;
                angle_scrunch = 0;
                minradius += largest_radius*2*radius_scrunch;
                largest_radius = 0;
                continue;
            }
		}
        
        /* This is the position of the center */
        ang[order[i]] = angle + degrees/2;
        angscrunch[order[i]] = angle_scrunch + degrees_scrunch/2;
        dist[order[i]] = radius;
        angle += degrees;
        angle_scrunch += degrees_scrunch;

        /* set angles to scrunch if we got out of jumping a row above
         * by using the small row scrunch */
        if (doscrunch) {
                for (j = first_in_this_ring; j <= i; j++) {
                    ang[order[j]] = angscrunch[order[j]];
                    angle = angle_scrunch;
                }
                doscrunch = 0;
        }
        i++;
	}
	/* Stretch out last ring to use whole angle */
	for (j = first_in_this_ring; j < i; j++)
		ang[order[j]] *= total_angle/angle;

	/* Start again with more stretch if too spaced out at end */
	if (first_in_this_ring && total_angle/angle > 1.2 * scrunch_factor &&
            !didscrunch) {
		scrunch_factor *= 1.02;
		goto again;
	}

	largest_radius = draw_images(argv, order, startangle, ang, dist, bound);

	printf("%% bound %.2f %.2f %.2f %.2f\n",
	       -largest_radius, -largest_radius, largest_radius, largest_radius);
	return 0;
}
