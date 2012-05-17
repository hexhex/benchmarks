#!/bin/bash

find . -name "*.cpp" -o -name "*.c" |xargs grep -L "#.*include.*config.h"
