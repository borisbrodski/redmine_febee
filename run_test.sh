#!/bin/sh
TESTS=$(find test/ -name \*$1\*test.rb)
for t in $TESTS ; do
  echo Test: $t
done
/usr/bin/ruby1.8 -I"lib" "/usr/lib/ruby/gems/1.8/gems/rake-0.8.7/lib/rake/rake_test_loader.rb" $TESTS
