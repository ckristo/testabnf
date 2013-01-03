testabnf
========

testabnf is a very simple bash script that allows to define test cases to check an ABNF grammer very easily. The script is a wrapper for the parse2 library that generates and executes a parser against an ABNF file.

Requirements:
* aparse.jar (download at http://www.parse2.com/download.shtml)
* (java, javac - JDK version that is needed by aparse)

Usage:

    testabnf.sh aparse.jar file.abnf test-file

* *file.abnf* : contains the ABNF grammar used to parse the test strings
* *test-file* : a text file that contains the test strings line by line with a prefixed sign indicating if the test should succeed or fail, e.g.:

> \+ a string that should be parsed successfully by aparse
> \- a string that should NOT be parsed successfully by aparse
> \# \+ a string that is ignored because it is commented-out
