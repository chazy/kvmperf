#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <getopt.h>
#include <errno.h>

static int x86mode = 0;

static double get_power(char *line)
{
	char *str, *str2 = NULL, *saveptr = NULL;
	while (str = strtok_r(line, " \t", &saveptr)) {
	       line = NULL;
	       str2 = str;
	}
	if (str2)
		return atof(str2);
	else
		return 0.0;
}

void usage(const char *arg0)
{
	fprintf(stderr, "Usage: %s [-x] [input file]\n\n"
		"Options:\n"
		"             -x:  x86 data format\n"
		"   [input file]:  input file name, stdin if ommitted",
		arg0);
	exit(EXIT_FAILURE);

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
			usage(argv[0]);
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
		double line_power;
		if (!x86mode && lineptr[0] == '#')
			continue;
		if (!x86mode && !strncmp(lineptr, "time", bufsize))
			continue;
		if (x86mode && (lineptr[0] < '0' || lineptr[0] > '9'))
			continue;
		line_power = get_power(lineptr);
		if (line_power == 0.0)
			continue;
		avg = (line_power + (double)datapoints * avg) /
			((double)datapoints + 1);
		datapoints++;
	}

	if (stream == stdin)
		printf("%f", avg);
	else
		printf("%f\n", avg);

	return 0;
}
