%{
#include "parser.tab.h"
#include "string.h"
#include "def.h"
int yycolumn=1;

#define YY_USER_ACTION    	yylloc.first_line=yylloc.last_line=yylineno; yylloc.first_column=yycolumn;	yylloc.last_column=yycolumn+yyleng-1; yycolumn+=yyleng;
typedef union {
	int type_int;
	int type_float;
	double type_double;
    char   type_char;
	char type_id[32];
	struct node *ptr;
} YYLVAL;
#define YYSTYPE YYLVAL

//%option yylineno 记录符号所在行号
%}
%option yylineno 

id   [A-Za-z][A-Za-z0-9]*  
int    [0-9]+
float  ([0-9]*\.[0-9]+)|([0-9]+\.)
double ([0-9]*\.[0-9]+)|([0-9]+\.)
char '.'|[0-9]+

%%
{int}        {yylval.type_int=atoi(yytext); return INT;} 
{float}      {yylval.type_float=atof(yytext); return FLOAT;}
{double}     {yylval.type_double=atof(yytext);return DOUBLE;}
{char}       {yylval.type_char=yytext[1];return CHAR;}
"int"        {strcpy(yylval.type_id, yytext);return TYPE;}
"float"      {strcpy(yylval.type_id, yytext);return TYPE;}
"double"     {strcpy(yylval.type_id, yytext);return TYPE;}
"char"       {strcpy(yylval.type_id, yytext);return TYPE;}
"struct"     {strcpy(yylval.type_id, yytext);return STRUCT;}

"return"     {return RETURN;}
"if"         {return IF;}
"else"       {return ELSE;}
"while"      {return WHILE;}

{id}        {strcpy(yylval.type_id,  yytext); return ID;}/*由于关键字的形式也符合表示符的规则，所以把关键字的处理全部放在标识符的前面，优先识别*/
";"			{return SEMI;}
","			{return COMMA;}
">"|"<"|">="|"<="|"=="|"!=" {strcpy(yylval.type_id, yytext);;return RELOP;}
"="			{return ASSIGNOP;}
"+"			{return PLUS;}
"-"			{return MINUS;}
"++"		{return INC;}
"--"		{return DEC;}
"+="		{return INCASS;}
"-="		{return DECASS;}
"*"			{return STAR;}
"/"			{return DIV;}
"&&"        {return AND;}
"||"        {return OR;}
"!"			{return NOT;}
"("			{return LP;}
")"			{return RP;}
"["         {return LB;}
"]"         {return RB;}
"{"			{return LC;}
"}"			{return RC;}
[\n]        {yycolumn=1;}   
[ \r\t]          {}   
.			{printf("Error type A :Mysterious character \"%s\"\n\t at Line %d\n",yytext,yylineno);}

 /*作为实验内容，还需要考虑识别出2种形式的注释注释部分时，直接舍弃 */
(\/\/).*    {}//匹配注释//
\/\*([^\*]|(\*)*[^\*/])*(\*)*\*\/ {} //匹配注释 /**/

%%

/* 和bison联用时，不需要这部分*/

// void main(int argc, char const *argv[])
// {
// 	yylex();
// 	return 0;
// }

//当Lex处理到输入串的文件尾时，自动地调用yywrap（），如果 yywrap（）返回值是 1，那么Lex就认为对输入的处理完全结束
int yywrap()
{
return 1;
}