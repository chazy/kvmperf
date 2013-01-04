#ifndef STREAMLINE_ANNOTATE_H
#define STREAMLINE_ANNOTATE_H

/*
 *  User-space only macros:
 *  ANNOTATE_DEFINE  You must put 'ANNOTATE_DEFINE;' one place in your program
 *  ANNOTATE_SETUP   Execute at the start of the program before other ANNOTATE macros are called
 *  
 *  User-space and Kernel-space macros:
 *  ANNOTATE(str)                                String annotation
 *  ANNOTATE_CHANNEL(channel, str)               String annotation on a channel
 *  ANNOTATE_COLOR(color, str)                   String annotation with color
 *  ANNOTATE_CHANNEL_COLOR(channel, color, str)  String annotation on a channel with color
 *  ANNOTATE_END()                               Terminate an annotation
 *  ANNOTATE_CHANNEL_END(channel)                Terminate an annotation on a channel
 *  ANNOTATE_NAME_CHANNEL(channel, group, str)   Name a channel and link it to a group
 *  ANNOTATE_NAME_GROUP(group, str)              Name a group
 *  ANNOTATE_VISUAL(data, length, str)           Image annotation with optional string
 *  ANNOTATE_MARKER()                            Marker annotation
 *  ANNOTATE_MARKER_STR(str)                     Marker annotation with a string
 *  ANNOTATE_MARKER_COLOR(color)                 Marker annotation with a color
 *  ANNOTATE_MARKER_COLOR_STR(color, str)        Marker annotation with a string and color
 *
 *  Channels and groups are defined per thread. This means that if the same
 *  channel number is used on different threads they are in fact separate
 *  channels. A channel can belong to only one group per thread. This means
 *  channel 1 cannot be part of both group 1 and group 2 on the same thread.
 *
 *  NOTE: Kernel annotations are not supported in interrupt context.
 */

// ESC character, hex RGB (little endian)
#define ANNOTATE_RED    0x0000ff1b
#define ANNOTATE_BLUE   0xff00001b
#define ANNOTATE_GREEN  0x00ff001b
#define ANNOTATE_PURPLE 0xff00ff1b
#define ANNOTATE_YELLOW 0x00ffff1b
#define ANNOTATE_CYAN   0xffff001b
#define ANNOTATE_WHITE  0xffffff1b
#define ANNOTATE_LTGRAY 0xbbbbbb1b
#define ANNOTATE_DKGRAY 0x5555551b
#define ANNOTATE_BLACK  0x0000001b

#include <stdio.h>
#include <string.h>
#include <stdint.h>

extern FILE *gator_annotate;

#define ANNOTATE_DEFINE   FILE *gator_annotate = 0

#define ANNOTATE_SETUP()  do { if (!gator_annotate) { \
	gator_annotate = fopen("/dev/gator/annotate", "wb"); \
	}} while(0)

#define ANNOTATE(str) ANNOTATE_CHANNEL(0, str)

#define ANNOTATE_CHANNEL(channel, str) do { if (gator_annotate) { \
	const char* gator_str = str; \
	const int gator_str_size = strlen(gator_str) & 0xffff; \
	const unsigned int gator_channel = channel; \
	const long long gator_header =  0x061c | ((unsigned long long)gator_channel << 16) | ((unsigned long long)gator_str_size << 48); \
	ANNOTATE_WRITE(&gator_header, sizeof(gator_header)); \
	ANNOTATE_WRITE(gator_str, gator_str_size); \
	fflush(gator_annotate); }} while(0)

#define ANNOTATE_COLOR(color, str) ANNOTATE_CHANNEL_COLOR(0, color, str)

#define ANNOTATE_CHANNEL_COLOR(channel, color, str) do { if (gator_annotate) { \
	const uint32_t gator_channel = channel; \
	const char* gator_str = str; \
	const int gator_str_size = (strlen(gator_str) + 4) & 0xffff; \
	const uint32_t gator_color = color; \
	char gator_header[12]; \
	gator_header[0] = 0x1c; \
	gator_header[1] = 0x06; \
	gator_header[2] = gator_channel & 0xff; \
	gator_header[3] = (gator_channel >> 8) & 0xff; \
	gator_header[4] = (gator_channel >> 16) & 0xff; \
	gator_header[5] = (gator_channel >> 24) & 0xff; \
	gator_header[6] = gator_str_size & 0xff; \
	gator_header[7] = (gator_str_size >> 8) & 0xff; \
	gator_header[8] = gator_color & 0xff; \
	gator_header[9] = (gator_color >> 8) & 0xff; \
	gator_header[10] = (gator_color >> 16) & 0xff; \
	gator_header[11] = (gator_color >> 24) & 0xff; \
	ANNOTATE_WRITE(&gator_header, sizeof(gator_header)); \
	ANNOTATE_WRITE(gator_str, gator_str_size - 4); \
	fflush(gator_annotate); }} while(0)

#define ANNOTATE_END() ANNOTATE_CHANNEL_END(0)

#define ANNOTATE_CHANNEL_END(channel) do { if (gator_annotate) { \
	const unsigned int gator_channel = channel; \
	const long long gator_header = 0x061c | ((unsigned long long)gator_channel << 16); \
	ANNOTATE_WRITE(&gator_header, sizeof(gator_header)); \
	fflush(gator_annotate); }} while(0)

#define ANNOTATE_NAME_CHANNEL(channel, group, str) do { if (gator_annotate) { \
	uint32_t gator_channel = channel; \
	uint32_t gator_group = group; \
	const char* gator_str = str; \
	const int gator_str_size = strlen(gator_str) & 0xffff; \
	char gator_header[12]; \
	gator_header[0] = 0x1c; \
	gator_header[1] = 0x07; \
	gator_header[2] = gator_channel & 0xff; \
	gator_header[3] = (gator_channel >> 8) & 0xff; \
	gator_header[4] = (gator_channel >> 16) & 0xff; \
	gator_header[5] = (gator_channel >> 24) & 0xff; \
	gator_header[6] = gator_group & 0xff; \
	gator_header[7] = (gator_group >> 8) & 0xff; \
	gator_header[8] = (gator_group >> 16) & 0xff; \
	gator_header[9] = (gator_group >> 24) & 0xff; \
	gator_header[10] = gator_str_size & 0xff; \
	gator_header[11] = (gator_str_size >> 8) & 0xff; \
	ANNOTATE_WRITE(&gator_header, sizeof(gator_header)); \
	ANNOTATE_WRITE(gator_str, gator_str_size); \
	fflush(gator_annotate); }} while(0)

#define ANNOTATE_NAME_GROUP(group, str) do { if (gator_annotate) { \
	const char* gator_str = str; \
	const int gator_str_size = strlen(gator_str) & 0xffff; \
	long long gator_header = 0x081c | ((uint32_t)(group) << 16) | ((long long)gator_str_size << 48); \
	ANNOTATE_WRITE(&gator_header, sizeof(gator_header)); \
	ANNOTATE_WRITE(gator_str, gator_str_size); \
	fflush(gator_annotate); }} while(0)

#define ANNOTATE_VISUAL(data, length, str) do { if (gator_annotate) { \
	const char* gator_str = str; \
	const int gator_str_size = strlen(gator_str) & 0xffff; \
	const int gator_local_length = length; \
	const int gator_header = 0x041c | (gator_str_size << 16); \
	ANNOTATE_WRITE(&gator_header, sizeof(gator_header)); \
	ANNOTATE_WRITE(gator_str, gator_str_size); \
	ANNOTATE_WRITE(&gator_local_length, sizeof(gator_local_length)); \
	ANNOTATE_WRITE((data), gator_local_length); \
	fflush(gator_annotate); }} while(0)

#define ANNOTATE_MARKER() do { if (gator_annotate) { \
	const int gator_header = 0x051c; \
	ANNOTATE_WRITE(&gator_header, sizeof(gator_header)); \
	fflush(gator_annotate); }} while(0)

#define ANNOTATE_MARKER_STR(str) do { if (gator_annotate) { \
	const char* gator_str = str; \
	const int gator_str_size = strlen(gator_str) & 0xffff; \
	const int gator_header =  0x051c | (gator_str_size << 16); \
	ANNOTATE_WRITE(&gator_header, sizeof(gator_header)); \
	ANNOTATE_WRITE(gator_str, gator_str_size); \
	fflush(gator_annotate); }} while(0)

#define ANNOTATE_MARKER_COLOR(color) do { if (gator_annotate) { \
	const int gator_color = color; \
	const long long gator_header = 0x0004051c | ((long long)gator_color << 32); \
	ANNOTATE_WRITE(&gator_header, sizeof(gator_header)); \
	fflush(gator_annotate); }} while(0)

#define ANNOTATE_MARKER_COLOR_STR(color, str) do { if (gator_annotate) { \
	const char* gator_str = str; \
	const int gator_str_size = (strlen(gator_str) + 4) & 0xffff; \
	const int gator_color = color; \
	const long long gator_header = 0x051c | (gator_str_size << 16) | ((long long)gator_color << 32); \
	ANNOTATE_WRITE(&gator_header, sizeof(gator_header)); \
	ANNOTATE_WRITE(gator_str, gator_str_size - 4); \
	fflush(gator_annotate); }} while(0)

// Not to be called by the user
#define ANNOTATE_WRITE(data, length) { \
	int annotate_pos = 0; \
	const int annotate_fwrite_length = length; \
	while ((annotate_pos < (int)annotate_fwrite_length) && !feof(gator_annotate) && !ferror(gator_annotate)) { \
		annotate_pos += fwrite(&((char*)(data))[annotate_pos], 1, annotate_fwrite_length - annotate_pos, gator_annotate); \
	} \
}

#endif // STREAMLINE_ANNOTATE_H
