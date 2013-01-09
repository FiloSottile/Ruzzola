#! /bin/bash
rm "$2"
cat "$1" | sed 'y/ /\n/' | egrep -v -i "[a-z]{15}" | egrep -i "[a-z]{2}" | sort > preproc.txt
for i in 2 3 4 6 8 10 12; do
	cat preproc.txt | cut -b 1-$i | egrep -i "[a-z]{$i}" | uniq | coffee make_bloom.coffee >> "$2"
	echo -n ";" >> "$2"
done
cat preproc.txt | coffee make_bloom.coffee words.bloom >> "$2"
rm preproc.txt
