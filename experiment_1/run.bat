bison -d -v -t .\parser.y
flex .\lex.l
gcc -o parser .\ast.c .\lex.yy.c .\parser.tab.c
parser.exe test.c > text.txt