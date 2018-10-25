%error-verbose
%locations
%{
#include "stdio.h"
#include "math.h"
#include "string.h"
#include "def.h"
extern int yylineno;
extern char *yytext;
extern FILE *yyin;
void yyerror(const char* fmt, ...);
void display(struct node *,int);
%}

//改变YYSTYPE的类型
%union {
	int    type_int;
	float  type_float;
        double type_double;
        char   type_char;
	char   type_id[32];
	struct node *ptr;
};

/**
可以把标志（token）绑定到YYSTYPE的某个域
如：%token <iValue> INTEGER 
    %type <nPtr> expr
把expr绑定到nPtr，把INTEGER绑定到iValue
yacc处理时会做转换
如：expr: INTEGER { $$ = con($1); }
转换结果为：yylval.nPtr = con(yyvsp[0].iValue);
其中yyvsp[0]是值栈（value stack）当前的头部
*/
//  %type 定义非终结符的语义值类型，如把program绑定到ptr
%type  <ptr> 
        program //初始语法单元
        ExtDefList //零个或多个ExtDef
        ExtDef //一个全局变量、结构体或函数的定义
        StructSpecifier //结构体描述符
        OptTag 
        Tag  
        Specifier //类型描述符
        ExtDecList //零个或多个VarDec
        FuncDec //函数头
        CompSt //函数体、由花括号括起来的语句块
        VarList //形参列表
        VarDec //一个变量的定义
        ParamDec //一个形参的定义
        Stmt //一条语句
        StmList //语句列表
        DefList //变量定义列表
        Def //一条变量定义
        DecList 
        Dec 
        Exp //一个表达式
        Args //实参列表

//% token 定义终结符的语义值类型
%token <type_int> INT              //指定INT的语义值是type_int，有词法分析得到的数值
%token <type_id> ID RELOP TYPE STRUCT   //指定ID,RELOP 的语义值是type_id，有词法分析得到的标识符字符串
%token <type_float> FLOAT         //指定ID的语义值是type_id，有词法分析得到的标识符字符串
%token <type_double> DOUBLE
%token <type_char> CHAR

//用bison对该文件编译时，带参数-d，生成的exp.tab.h中给这些单词进行编码，可在lex.l中包含parser.tab.h使用这些单词种类码
%token  LP //(
        RP //)
        LB //[
        RB //]
        LC //{
        RC //}
        SEMI //;
        COMMA  //,
%token  PLUS //+
        MINUS //-
        STAR //*
        DIV // /
        ASSIGNOP //=
        AND //&&
        OR // ||
        NOT //!
        IF 
        ELSE 
        WHILE 
        RETURN
        INC
        DEC
        INCASS
        DECASS

%left ASSIGNOP
%left OR
%left AND
%left RELOP //运算符
%left INC DEC INCASS DECASS
%left PLUS MINUS
%left STAR DIV
%right UMINUS NOT //UMINUS ？？？
//%nonassoc的含义是没有结合性。它一般与%prec结合使用表示该操作有同样的优先级
%nonassoc LOWER_THEN_ELSE
%nonassoc ELSE

%%

/* 递归解析
左递归形式：
list: item 
    | list ',' item;
右递归形式：
list: item 
     | item ',' list
使用右递归时，所有的项都压入堆栈里，才开始规约
而使用左递归的话，同一时刻不会有超过三个项在堆栈里
*/

//display在ast.c中定义，semantic_Analysis0在def.h中定义
//$$表示规约后的值;$1表示右边的第一个标记的值，$2表示右边的第二个标记的值，依次类推
/*
如：expr: INTEGER { $$ = con($1); } 转换结果为：yylval.nPtr = con(yyvsp[0].iValue);
其中yyvsp[0]是值栈（value stack）当前的头部
*/

//初始语法单元，表示整个程序
program: ExtDefList { display($1,0);}     /*显示语法树,语义分析*///; semantic_Analysis0($1)
         ; 
//表示零个或多个 ExtDef
ExtDefList: {$$=NULL;}
          | ExtDef ExtDefList {$$=mknode(EXT_DEF_LIST,$1,$2,NULL,yylineno);}   //每一个EXTDEFLIST的结点，其第1棵子树对应一个外部变量声明或函数
          ; 
//一个全局变量、结构体或函数的定义
ExtDef:   Specifier ExtDecList SEMI   {$$=mknode(EXT_VAR_DEF,$1,$2,NULL,yylineno);}   //该结点对应一个外部变量声明（全局变量）
         |Specifier SEMI              {$$=mknode(STRUCT_DEF,$1,NULL,NULL,yylineno);}  //为定义结构体
         |Specifier FuncDec CompSt    {$$=mknode(FUNC_DEF,$1,$2,$3,yylineno);}        //该结点对应一个函数定义
         | error SEMI   {$$=NULL; }
         ;
//定义结构体
StructSpecifier: STRUCT OptTag LC DefList RC {$$=mknode(STRUCT_DEF,$2,$4,NULL,yylineno);strcpy($$->type_id,$1);}//定义结构体的基本格式
        | STRUCT Tag {$$=mknode(STRUCT_DEF,$2,NULL,NULL,yylineno);strcpy($$->type_id,$1);}//定义结构体变量
        ;
//类型描述符：TYPE-->int/float等；StructSpecifier-->结构体
Specifier:  TYPE {$$=mknode(TYPE,NULL,NULL,NULL,yylineno);strcpy($$->type_id,$1);
        if(!strcmp($1,"int")) $$->type=INT;
        if(!strcmp($1,"float")) $$->type=FLOAT;
        if(!strcmp($1,"double")) $$->type=DOUBLE;
        if(!strcmp($1,"char")) $$->type=CHAR;}
        | StructSpecifier {$$=mknode(STRUCT_DEF,$1,NULL,NULL,yylineno);}
        ; 
//结构体名：struct OptTag{...}
OptTag: ID {$$=mknode(ID,NULL,NULL,NULL,yylineno);strcpy($$->type_id,$1);}
        | {printf("OptTag");$$=NULL;}
        ;
//已定义结构体名：OptTag Tag；像 int a一样
Tag: ID {$$=mknode(ID,NULL,NULL,NULL,yylineno);strcpy($$->type_id,$1);}
        ;
ExtDecList:  VarDec {$$=$1;}  /*每一个EXT_DECLIST的结点，其第一棵子树对应一个变量名(ID类型的结点),第二棵子树对应剩下的外部变量名*/
           | VarDec COMMA ExtDecList {$$=mknode(EXT_DEC_LIST,$1,$3,NULL,yylineno);}
           ;  
//表示对一个变量的定义
VarDec:  ID {$$=mknode(ID,NULL,NULL,NULL,yylineno);strcpy($$->type_id,$1);}   //ID结点，标识符符号串存放结点的type_id
        | VarDec LB INT RB {$$=mknode(ARRAY_DEF,$1,NULL,NULL,yylineno);$$->type_id[0]=$3;}//一维数组
        ;
//表示对一个函数头的定义
FuncDec: ID LP VarList RP   {$$=mknode(FUNC_DEC,$3,NULL,NULL,yylineno);strcpy($$->type_id,$1);}//函数名存放在$$->type_id
	|ID LP  RP   {$$=mknode(FUNC_DEC,NULL,NULL,NULL,yylineno);strcpy($$->type_id,$1);}//函数名存放在$$->type_id
        ; 
//包括一个或多个ParamDec
VarList: ParamDec  {$$=mknode(PARAM_LIST,$1,NULL,NULL,yylineno);}
        | ParamDec COMMA  VarList  {$$=mknode(PARAM_LIST,$1,$3,NULL,yylineno);}
        ;
//对一个形参的定义
ParamDec: Specifier VarDec         {$$=mknode(PARAM_DEC,$1,$2,NULL,yylineno);}
         ;
//表示由一对花括号括起来的语句块；因此必须在每个语句块的开头才可以定义变量
CompSt: LC DefList StmList RC    {$$=mknode(COMP_STM,$2,$3,NULL,yylineno);}
       ;
//零个或多个Stmt的组合，即语句定义集合
StmList: {$$=NULL; }  
        | Stmt StmList  {$$=mknode(STM_LIST,$1,$2,NULL,yylineno);}
        ;
//表示一条语句
Stmt:   Exp SEMI    {$$=mknode(EXP_STMT,$1,NULL,NULL,yylineno);}//在末尾添加了分号的表达式
      | CompSt      {$$=$1;}      //复合语句结点直接最为语句结点，不再生成新的结点；另一个语句块
      | RETURN Exp SEMI   {$$=mknode(RETURN,$2,NULL,NULL,yylineno);}//一条返回语句
      | IF LP Exp RP Stmt %prec LOWER_THEN_ELSE   {$$=mknode(IF_THEN,$3,$5,NULL,yylineno);}//一条IF语句
      | IF LP Exp RP Stmt ELSE Stmt   {$$=mknode(IF_THEN_ELSE,$3,$5,$7,yylineno);}//一条IF-ELSE语句
      | WHILE LP Exp RP Stmt {$$=mknode(WHILE,$3,$5,NULL,yylineno);}//一条WHILE语句
      ;
//由多个Def组成
DefList: {$$=NULL; }
        | Def DefList {$$=mknode(DEF_LIST,$1,$2,NULL,yylineno);}
        ;
//变量定义
Def:    Specifier DecList SEMI {$$=mknode(VAR_DEF,$1,$2,NULL,yylineno);}//如：int a,b,c;
        ;
DecList: Dec  {$$=mknode(DEC_LIST,$1,NULL,NULL,yylineno);}
        | Dec COMMA DecList  {$$=mknode(DEC_LIST,$1,$3,NULL,yylineno);}
	;
Dec:    VarDec  {$$=$1;}
        | VarDec ASSIGNOP Exp  {$$=mknode(ASSIGNOP,$1,$3,NULL,yylineno);strcpy($$->type_id,"ASSIGNOP");}//如：int a = 5;
        ;
Exp:    Exp ASSIGNOP Exp {$$=mknode(ASSIGNOP,$1,$3,NULL,yylineno);strcpy($$->type_id,"ASSIGNOP");}//赋值表达式；$$结点type_id空置未用，正好存放运算符
      | Exp AND Exp   {$$=mknode(AND,$1,$3,NULL,yylineno);strcpy($$->type_id,"AND");}//逻辑与
      | Exp OR Exp    {$$=mknode(OR,$1,$3,NULL,yylineno);strcpy($$->type_id,"OR");}//逻辑或
      | Exp RELOP Exp {$$=mknode(RELOP,$1,$3,NULL,yylineno);strcpy($$->type_id,$2);}  //关系表达式；词法分析关系运算符号自身值保存在$2中
      | Exp PLUS Exp  {$$=mknode(PLUS,$1,$3,NULL,yylineno);strcpy($$->type_id,"PLUS");}//四则运算：加
      | Exp MINUS Exp {$$=mknode(MINUS,$1,$3,NULL,yylineno);strcpy($$->type_id,"MINUS");}//四则运算：减
      | Exp STAR Exp  {$$=mknode(STAR,$1,$3,NULL,yylineno);strcpy($$->type_id,"STAR");}////四则运算：乘
      | Exp DIV Exp   {$$=mknode(DIV,$1,$3,NULL,yylineno);strcpy($$->type_id,"DIV");}//四则运算：除
      | Exp INC       {$$=mknode(INC,$1,NULL,NULL,yylineno);strcpy($$->type_id,"INC");}
      | Exp DEC       {$$=mknode(DEC,$1,NULL,NULL,yylineno);strcpy($$->type_id,"DEC");}
      | Exp INCASS Exp   {$$=mknode(INCASS,$1,$3,NULL,yylineno);strcpy($$->type_id,"INCASS");}
      | Exp DECASS Exp   {$$=mknode(INCASS,$1,$3,NULL,yylineno);strcpy($$->type_id,"DECASS");}
      | LP Exp RP     {$$=$2;} //括号表达式
      | MINUS Exp %prec UMINUS   {$$=mknode(UMINUS,$2,NULL,NULL,yylineno);strcpy($$->type_id,"UMINUS");}//取负
      | NOT Exp       {$$=mknode(NOT,$2,NULL,NULL,yylineno);strcpy($$->type_id,"NOT");}//逻辑非
      | ID LP Args RP {$$=mknode(FUNC_CALL,$3,NULL,NULL,yylineno);strcpy($$->type_id,$1);}//函数调用表达式：带参数
      | ID LP RP      {$$=mknode(FUNC_CALL,NULL,NULL,NULL,yylineno);strcpy($$->type_id,$1);}//函数调用表达式：不带参数
      | Exp LB Exp RB {$$=mknode(FUNC_CALL,$1,NULL,$3,yylineno);}  //数组访问表达式
      | Exp STRUCT ID {$$=mknode(ID,$1,NULL,NULL,yylineno);strcpy($$->type_id,$2);}//结构体访问表达式
      | ID            {$$=mknode(ID,NULL,NULL,NULL,yylineno);strcpy($$->type_id,$1);}
      | INT           {$$=mknode(INT,NULL,NULL,NULL,yylineno);$$->type_int=$1;$$->type="INT";}
      | FLOAT         {$$=mknode(FLOAT,NULL,NULL,NULL,yylineno);$$->type_float=$1;$$->type="FLOAT";}
      | DOUBLE        {$$=mknode(DOUBLE,NULL,NULL,NULL,yylineno);$$->type_double=$1;$$->type="DOUBLE";}
      | CHAR          {$$=mknode(CHAR,NULL,NULL,NULL,yylineno);$$->type_char=$1;$$->type="CHAR";}
      ;
//实参列表，每个实参都可以变为一个表达式Exp
Args:    Exp COMMA Args    {$$=mknode(ARGS,$1,$3,NULL,yylineno);}
       | Exp               {$$=mknode(ARGS,$1,NULL,NULL,yylineno);}
       ;
       
%%
//当yacc解析出错时，会调用函数yyerror()
//调用yacc解析入口函数yyparse()
int main(int argc, char *argv[]){
	yyin=fopen(argv[1],"r");
	if (!yyin) return 1;
	yylineno=1;
        // yydebug=1;
	yyparse();
	return 0;
	}

#include<stdarg.h>
void yyerror(const char* fmt, ...)
{
    va_list ap;
    va_start(ap, fmt);
    fprintf(stderr, "Grammar Error at Line %d Column %d: ", yylloc.first_line,yylloc.first_column);
    vfprintf(stderr, fmt, ap);
    fprintf(stderr, ".\n");
}