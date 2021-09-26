# 2021-spring-compiler

## assignment description 
* third assignment : generate assembly code for the Java Virtual Machine by augmenting yacc parser

## Debug

` $ make clean && make ` 

` $ ./myscanner < input/in01_arithmetic.c >| tmp.out `

` $ diff -y tmp.out answer/in01_arithmetic.out `

## Judge

` python3 judge/judge.py `

## Environmental Setup
* For Linux
  * Ubuntu 18.04 LTS
  * Install dependencies: $ sudo apt install flex bison
  * Java Virtual Machine (JVM): $ sudo apt install default-jre
