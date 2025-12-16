%{
#include <stdio.h>
#include "limbaj.tab.h"
#include <string>
%}
%option noyywrap
%%
"int"|"float"|"char"|"string" {yylval.Str = new std::string(yytext); return TYPE;}
"begin_progr" {return BGIN;}
"end_progr" {return END;}
[a-zA-Z][a-zA-Z0-9]* {yylval.Str = new std::string(yytext); return ID;}
":=" {return ASSIGN;}
[0-9]+ {return NR;}
[0-9]+[.][0-9]+ {return NR_FLOAT;}
[ \t] ;
\n {yylineno++;}
. {return yytext[0];}

 /// SCANNER
