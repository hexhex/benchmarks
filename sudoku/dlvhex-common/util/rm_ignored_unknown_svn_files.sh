#!/bin/sh

echo "going to remove these files:"
svn status --no-ignore |grep "^[\?I]" |cut -b2-100
echo "answer 'yes' to execute, abort with CTRL+C"
read ANSWER
echo "answer was '${ANSWER}'"
if test "x${ANSWER}" = "xyes"; then
  svn status --no-ignore |grep "^[\?I]" |cut -b2-100 |xargs rm -v
fi

