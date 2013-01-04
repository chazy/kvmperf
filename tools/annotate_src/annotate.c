#include <stdio.h>
#include <stdlib.h>
#include "annotate.h"

ANNOTATE_DEFINE;


static void usage(const char *arg0)
{
	fprintf(stderr, "Usage: %s [-m] <marker text>\n", arg0);
}

static void annotate_end(void)
{
	ANNOTATE_END();
}

static void do_annotate(char marker, const char *msg)
{
	if (marker)
		ANNOTATE_MARKER_STR(msg);
	else
		ANNOTATE(msg);
	annotate_end();
}


int main(int argc, const char *argv[])
{
	int argp = 1;
	char marker = 0;
	const char *msg;

	if (argc < 2 || argc > 3) {
		usage(argv[0]);
		exit(EXIT_FAILURE);
	}

#if 0
	if (argc == 2 && !strcmp(argv[1], "-e")) {
		annotate_end();
		return;
	}
#endif

	if (argc == 3) {
		if (strcmp(argv[1], "-m")) {
			usage(argv[0]);
			exit(EXIT_FAILURE);
		}
		marker = 1;
		argp++;
	}

	msg = argv[argp];

	ANNOTATE_SETUP();
	do_annotate(marker, msg);

	return 0;
}
