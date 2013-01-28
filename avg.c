#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <getopt.h>
#include <errno.h>

static int x86mode = 0;

static double get_power(char *line)
{
	char *str, *str2, *saveptr = NULL;
	while (str = strtok_r(line, " \t", &saveptr)) {
	       line = NULL;
	       str2 = str;
	}
	return atof(str2);
}

int main(int argc, char * const argv[])
{
	ssize_t ret;
	size_t bufsize = 0;
	FILE *stream;
	char *lineptr = NULL;
	char *fname;
	double avg = 0;
	long long datapoints = 1;
	int opt;

	while ((opt = getopt(argc, argv, "x")) != -1) {
		switch (opt) {
		case 'x':
			x86mode = 1;
			break;
		default:
			fprintf(stderr, "Unknown argument: %s\n", argv[optind]);
		}
	}

	if (optind >= argc) {
		stream = stdin;
	} else {
		/* first positional argument is file name */
		fname = argv[optind];
		stream = fopen(fname, "r");
		if (!stream) {
			fprintf(stderr, "Error opening file %s: %s",
				fname, strerror(errno));
			exit(1);
		}
		printf("%s\t", fname);
	}


	while (getline(&lineptr, &bufsize, stream) > 0) {
		if (!x86mode && lineptr[0] == '#')
			continue;
		if (!x86mode && !strncmp(lineptr, "time", bufsize))
			continue;
		if (x86mode && (lineptr[0] < '0' || lineptr[0] > '9'))
			continue;
		avg = (get_power(lineptr) + (double)datapoints * avg) /
			((double)datapoints + 1);
		datapoints++;
	}

	printf("%f\n", avg);

	return 0;
}
