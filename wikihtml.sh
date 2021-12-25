#!/bin/bash

FORCE="$1"
SYNTAX="$2"
EXTENSION="$3"
OUTPUTDIR="$4"
INPUT="$5"
CSSFILE="$6"

FILE=$(basename "$INPUT")
FILENAME=$(basename "$INPUT" .$EXTENSION)
FILEPATH=${INPUT%$FILE}
OUTDIR=${OUTPUTDIR%$FILEPATH*}
OUTPUT="$OUTDIR"/$FILENAME
#CSSFILENAME=$(basename "$6")
CSSFILENAME=~/blogpost.css
NAME=$(echo $FILE | sed "s/.md//g")
HAS_MATH=$(grep -o "\$\$.\+\$\$" "$INPUT")


if [ ! -z "$HAS_MATH" ]; then
     MATH="--mathjax=https://cdn.jsdelivr.net/npm/mathjax@3.0.1/es5/tex-mml-chtml.js"
else
    MATH=""
fi


sed -r 's/(\[.+\])\(([^)]+)\)/\1(\2.html)/g' <"$INPUT" | sed -r 's/^[ ]*\*/-/g' | sed -r 's/^[ \t]\*/-/g' | sed 's/\.md.html)/.html)/g' | pandoc $MATH -s -f $SYNTAX -t html -c $CSSFILENAME --template ~/template.html --metadata title=$NAME >"$OUTPUT.html"
