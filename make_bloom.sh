#! /bin/bash
rm "$2"
for i in `seq -w 2 19`; do 
	cat "$1" | cut -b 1-$i | egrep -i "[a-z]{$i}" | uniq | coffee make_bloom.coffee >> "$2"
	echo -n ";" >> "$2"
done
cat "$1" | coffee make_bloom.coffee words.bloom >> "$2"
