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

# Columns
#
#   General:
#   1:size 2:to
#
#   For each configuration:
#   1:wallclock 2:wallclock_to 3:grounding 4:grounding_to 5:solve 6:solve_to
#      7:pathexists 8:pathexists_to 9:pathlen 10:pathlen_to 11:changes 12:changes_to 13:lunch 14:lunch_to

confs <- (ncol(output) - 2) / 14
for (c in 1:confs){

	offset <- 2 + (c-1) * 14

	# fix pathexists column
	output[,offset+7] <- round(100 * output[,offset+7],2)
	output[,offset+8] <- \"x\"

	# fix path length column
	output[,offset+9] <- (100 * output[,offset+9]) / output[,offset+7]
	output[,offset+9] <- round(output[,offset+9],2)
	output[,offset+10] <- \"x\"

	# fix changes column
	output[,offset+11] <- (output[,offset+11] * 100) / output[,offset+7]
	output[,offset+11][which(output[,offset+7] == 0)] <- NaN
	output[,offset+11] <- (output[,offset+11] - 2 * ((output[,1] + 1) * 2 - 2))
	output[,offset+11] <- round(output[,offset+11],2)
	output[,offset+12] <- \"x\"

	# fix restaurant column
	output[,offset+13] <- (output[,offset+13] * 100) / output[,offset+7]
	output[,offset+13][which(output[,offset+7] == 0)] <- NaN
	output[,offset+13] <- round(100 * output[,offset+13],2)
	output[,offset+14] <- \"x\"
}

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
