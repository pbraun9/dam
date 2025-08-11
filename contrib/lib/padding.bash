
chars_num=`echo -n $index | wc -c`
#echo debug: $chars_num chars
if (( chars_num < 8 )); then
        echo -ne "$index\t\t\t\t\t\t\t\t\t\t\t"
elif (( chars_num < 16 )); then
        echo -ne "$index\t\t\t\t\t\t\t\t\t\t"
elif (( chars_num < 24 )); then
        echo -ne "$index\t\t\t\t\t\t\t\t\t"
elif (( chars_num < 32 )); then
        echo -ne "$index\t\t\t\t\t\t\t\t"
elif (( chars_num < 40 )); then
        echo -ne "$index\t\t\t\t\t\t\t"
elif (( chars_num < 48 )); then
        echo -ne "$index\t\t\t\t\t\t"
elif (( chars_num < 56 )); then
        echo -ne "$index\t\t\t\t\t"
elif (( chars_num < 64 )); then
        echo -ne "$index\t\t\t\t"
elif (( chars_num < 72 )); then
        echo -ne "$index\t\t\t"
elif (( chars_num < 80 )); then
        echo -ne "$index\t\t"
else
        echo -ne "$index\t"
fi

