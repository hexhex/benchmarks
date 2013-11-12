while read line
do
        read -a array <<< "$line"
        if [[ $line != \#* ]]; then
                fn=${array[0]}
                line=$(echo ${array[@]} | grep -v "#" | sed "s/ *\([^ ]*\) *\([^ ]*\) */\1 (\2) \& /g" | sed -e "s/(\([0-9]\))/~~(\1)/g" | sed -e "s/\& $/\\\\\\\\/" | sed "s/ (x)//g")
                file=$(echo "$file\n$line")
                echo $line
        fi
done

