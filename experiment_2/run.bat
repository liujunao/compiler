gcc -o parser ast.c .\symbol.c .\lex.yy.c .\parser.tab.c
parser.exe test.c > text.txt