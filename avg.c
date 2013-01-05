#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static double getPower(char *line)
{
	char *str, *str2, *saveptr = NULL;
	while (str = strtok_r(line, " \t", &saveptr)) {
	       line = NULL;
	       str2 = str;
	}
	return atof(str2);
}

int main(int argc, const char *argv[])
{
	ssize_t ret;
	size_t bufsize = 0;
	FILE *stream;
	char *lineptr = NULL;
	double avg = 0;
	long long datapoints = 1;

	if (argc == 2) {
		stream = fopen(argv[1], "r");
		if (!stream) {
			perror("opening file");
			exit(1);
		}
		printf("%s\t", argv[1]);
	} else {
		stream = stdin;
	}

	while (getline(&lineptr, &bufsize, stream) > 0) {
		if (lineptr[0] == '#')
			continue;
		if (!strncmp(lineptr, "time", bufsize))
			continue;
		avg = (getPower(lineptr) + (double)datapoints * avg) / ((double)datapoints + 1);
		datapoints++;
	}

	printf("%f\n", avg);

	return 0;
}
