%{
#include <stdio.h>
#include "limbaj.tab.h"
#include "SymTable.h"
#include <string>
extern SymTable* current;

%}

%option noyywrap
%%
"int"|"float"|"char"|"string"|"bool" {yylval.Str = new std::string(yytext); return TYPE;}
"begin_progr" {return BGIN;}
"end_progr" {return END;}
"true"|"false" {yylval.Str = new std::string(yytext); return BOOL_VAL;}
"Print" {return PRINT;}
"class" {return CLASS;}
"." {return DOT;}
"if" {return IF;}
"while" {return WHILE;}
[a-zA-Z][a-zA-Z0-9]* {
    
    yylval.Str = new std::string(yytext);
    
    if(current != NULL)
    {
        std::string type = current->getType(yylval.Str);

        if(type == "int" || type == "float")
        {
            return ID_ARITH;
        }
        if(type == "bool")
        {
            return ID_BOOL;
        }
    }

    return ID;
}
":=" {return ASSIGN;}
[0-9]+ {return NR;}
[0-9]+[.][0-9]+ {return NR_FLOAT;}
"==" {return EQ;}
"!=" {return NEQ;}
"<" {return LT;}
">" {return GT;}
"<=" {return LE;}
">=" {return GE;}
"&&" {return AND;}
"||" {return OR;}
[ \t] ;
\n {yylineno++;}
. {return yytext[0];}

