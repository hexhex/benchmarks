# converts instances given as ASP facts to our proprietary format
sed 's/(/ /g' | sed 's/)/ /g' | sed 's/,/ /g' | sed 's/\./ /g'
