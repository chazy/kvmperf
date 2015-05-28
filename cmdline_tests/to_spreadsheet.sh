#!/bin/sh

# Passes stdin of an exit analysis dump through AWK to create tab-separated
# columns for easy import to Excel.


tail -n 19 | sed -e 's/^[ \t]*//' | awk 'BEGIN { FS=" {2,}"; OFS="\t"; } { $1 = $1; print }'
