# 2021-spring-compiler

## assignment description 
* second assignment : the syntactic definition in yacc

## Debug

` $ make clean && make ` 

` $ ./myscanner < input/in01_arithmetic.c >| tmp.out `

` $ diff -y tmp.out answer/in01_arithmetic.out `

## Judge

` python3 judge/judge.py `

## Environmental Setup
* For Linux
  * Ubuntu 18.04 LTS
  * Install dependencies: $ sudo apt install gcc flex bison python3 git
