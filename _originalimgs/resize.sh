for file in *.jpg
do
  convert $file -resize 640 ../images/$file
done

for file in *.png
do
  convert $file -resize 640 ../images/$file
done
