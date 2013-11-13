to="300.00"
if [ $# -le 2 ]; then
	echo "Wrong number of arguments"
	exit 1;
fi

to=$1
extrstart=$2
extrlen=$3
totex=0
if [ $# -ge 4 ]; then
	totex=$4
fi

aggregate="
library(doBy);

t <- read.table('stdin',header=FALSE,as.is=TRUE)

# extract odd and even columns
odd <- c(1,seq(3,ncol(t),2))
even <- c(1,2,seq(4,ncol(t),2))

# compute means of odd and sums of even columns
means <- summaryBy(.~V1, data=t[,odd], FUN=mean)
sums <- summaryBy(.~V1, data=t[,even], FUN=sum)

#interleave the columns again
merged <- merge(means,sums)
g <-    function(x){
                 if ( x == 1 ){
                        return (1);
                }else if ( x == 2 ){
                        return (ncol(means) + 1);
                }else{
                        if (x %% 2 != 0 ){
                                return (1 + (x - 1) / 2);
                        }else{
                                return (ncol(means) + x / 2);
                        }
                }
        }

mixed <- sapply(seq(1,ncol(merged)), FUN=g)
merged <- merged[mixed]

# round all values in odd columns except in column 1
output <- merged
odd <- seq(3,ncol(output),2)
output[odd] <- round(output[odd],2)

# Columns:
#   1:size 2:to
#   3:ss_wallclock 4:ss_wallclock_to 5:ss_grounding 6:ss_grounding_to 7:ss_solve 8:ss_solve_to
#      9:ss_pathexists 10:ss_pathexists_to 11:ss_pathlen 12:ss_pathlen_to 13:ss_changes 14:ss_changes_to 15:ss_lunch 16:ss_lunch_to

#   17:ls_wallclock 18:ls_wallclock_to 19:ls_grounding 20:ls_grounding_to 21:ls_solve 22:ls_solve_to
#      23:ls_pathexists 24:ls_pathexists_to 25:ls_pathlen 26:ls_pathlen_to 27:ls_changes 28:ls_changes_to 29:ls_lunch 30:ls_lunch_to

# fix pathexists columns
output[,9] <- round(100 * output[,9],2)
output[,23] <- round(100 * output[,23],2)
output[,9][which(output[,9] == 0)] <- NaN
output[,23][which(output[,23] == 0)] <- NaN
output[,10] <- \"x\"
output[,24] <- \"x\"

# fix path length columns
output[,11] <- (100 * output[,11]) / output[,9]
output[,25] <- (100 * output[,25]) / output[,23]
output[,11] <- round(output[,11],2)
output[,25] <- round(output[,25],2)
output[,12] <- \"x\"
output[,26] <- \"x\"

# fix changes columns
output[,13] <- (output[,13] * 100) / output[,9]
output[,27] <- (output[,27] * 100) / output[,23]
output[,13][which(output[,9] == 0)] <- NaN
output[,27][which(output[,23] == 0)] <- NaN
output[,13] <- (output[,13] - (output[,1] * 2 - 2))
output[,27] <- (output[,27] - (output[,1] * 2 - 2))
output[,13] <- round(output[,13],2)
output[,27] <- round(output[,27],2)
output[,14] <- \"x\"
output[,28] <- \"x\"

# fix restaurant columns
output[,15] <- (output[,15] * 100) / output[,9]
output[,29] <- (output[,29] * 100) / output[,23]
output[,15][which(output[,9] == 0)] <- NaN
output[,29][which(output[,23] == 0)] <- NaN
output[,15] <- round(100 * output[,15],2)
output[,29] <- round(100 * output[,29],2)
output[,16] <- \"x\"
output[,30] <- \"x\"

write.table(format(output, nsmall=2, scientific=FALSE), , , FALSE, , , , , FALSE, FALSE)
"

while read line
do
	read -a array <<< "$line"
	if [[ $line != \#* ]]; then
		fn=${array[0]}
		if [ $extrlen -ge 1 ]; then
			array[0]="${fn:$extrstart:$extrlen} 1"
		else
			array[0]="${array[0]} 1"
		fi
		line=$(echo ${array[@]} | grep -v "#" | sed "s/\ \([0-9]*\)\.\([0-9]*\)/ \1.\2 0/g" | sed "s/--- --- --- --- --- --- ---/$to 1 $to 1 0 0 0 0 0 0 0 0 0 0/g")
		file=$(echo "$file\n$line")
	fi
done
if [ $totex -ge 1 ]; then
	# 1. encapsulate every second word in () and append &
	# 2. replace & at the end of the line with \\
	echo -e $file | Rscript <(echo "$aggregate") | sed "s/ -1[^ ]*//g" | sed "s/ *\(\S*\) *\(\S*\) */ \1 (\2) \& /g" | sed "s/\& *$/\\\\\\\\/g"
else
	echo -e $file | Rscript <(echo "$aggregate") | sed "s/ -1[^ ]*//g"
fi
