#!/bin/bash

for file in *.jpg
do
  convert $file -resize 640 ../images/$file
done

for file in *.png
do
  convert $file -resize 640 ../images/$file
done

# No resize
cd noresize
for file in *.png
do
  cp $file ../../images/$file
done
