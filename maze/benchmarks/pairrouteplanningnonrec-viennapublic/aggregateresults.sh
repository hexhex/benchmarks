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

# fix path length columns
output[,9] <- (output[,9] * output[,2]) / (output[,2] - output[,4])
output[,21] <- (output[,21] * output[,2]) / (output[,2] - output[,16])
output[,9] <- round(output[,9],2)
output[,21] <- round(output[,21],2)
output[,10] <- -1
output[,22] <- -1

# fix changes columns
output[,11] <- (output[,11] * output[,2]) / (output[,2] - output[,4])
output[,23] <- (output[,23] * output[,2]) / (output[,2] - output[,16])
output[,11][which(output[,4] == output[,2])] <- NaN
output[,23][which(output[,16] == output[,2])] <- NaN
output[,11] <- (output[,11] - (output[,1] * 2 - 2))
output[,23] <- (output[,23] - (output[,1] * 2 - 2))
output[,11] <- round(output[,11],2)
output[,23] <- round(output[,23],2)
output[,12] <- -1
output[,24] <- -1

# fix restaurant columns
output[,13] <- (output[,13] * output[,2]) / (output[,2] - output[,4])
output[,25] <- (output[,25] * output[,2]) / (output[,2] - output[,16])
output[,13][which(output[,4] == output[,2])] <- NaN
output[,25][which(output[,16] == output[,2])] <- NaN
output[,13] <- round(output[,13],2)
output[,25] <- round(output[,25],2)
output[,14] <- output[,13] * 100
output[,26] <- output[,25] * 100

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
		line=$(echo ${array[@]} | grep -v "#" | sed "s/\ \([0-9]*\)\.\([0-9]*\)/ \1.\2 0/g" | sed "s/--- --- --- --- --- ---/$to 1 $to 1 0 0 0 0 0 0 0 0/g")
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
