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

t <- read.table('data2',header=FALSE,as.is=TRUE)

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

# round all values except in column 1
output <-round(merged[,-1],2)

write.table(format(output, digits=2), , , FALSE, , , , , TRUE, FALSE)
"

while read line
do
	read -a array <<< "$line"
	fn=${array[0]}
	array[0]="${fn:$extrstart:$extrlen} 1"
	line=$(echo ${array[@]} | grep -v "#" | sed "s/\ \([0-9]*\)\.\([0-9]*\)/ \1.\2 0/g" | sed "s/---/$to 1/g")
	file=$(echo "$file\n$line")
done
if [ $totex -ge 1 ]; then
	echo -e $file | Rscript <(echo "$aggregate") | sed "s/\\n/\\\\\\n/g" | sed "s/\([0-9]*\.[0-9]*\)\ *\([0-9]*\)/\& \1 (\2)/g" | sed "s/$/ \\\\\\\\/g"
else
	echo -e $file | Rscript <(echo "$aggregate")
fi
