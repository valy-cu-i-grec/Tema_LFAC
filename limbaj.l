%{
#include <stdio.h>
#include <string>
#include "limbaj.tab.h"

%}

%option noyywrap

%%

"int"|"float"|"char"|"string"|"bool" { yylval.strVal = new std::string(yytext); return TYPE; }
"begin_progr" { return BGIN; }
"end_progr"   { return END; }
"true"|"false" { yylval.strVal = new std::string(yytext); return BOOL_VAL; } /* Returnam tipul direct */
"Print"       { return PRINT; }
"class"       { return CLASS; }
"."           { return DOT; }
"if"          { return IF; }
"else"        { return ELSE; }
"while"       { return WHILE; }
"return" { return RETURN; }


\"[a-zA-Z0-9 ]*\" { yylval.strVal = new std::string(yytext); return STRING; }
\'[a-zA-Z0-9]\'   { yylval.strVal = new std::string(yytext); return CHAR; }

[a-zA-Z][a-zA-Z0-9_]* { 
    yylval.strVal = new std::string(yytext); 
    return ID; 
}

":=" { return ASSIGN; }

[-]*[1-9]+[0-9]*|0  { yylval.strVal = new std::string(yytext); return NR; }
[-]*[0-9]+[.][0-9]+ { yylval.strVal = new std::string(yytext); return NR_FLOAT; }

"==" { return EQ; }
"!=" { return NEQ; }
"<"  { return LT; }
">"  { return GT; }
"<=" { return LE; }
">=" { return GE; }
"&&" { return AND; }
"||" { return OR; }
"+"  { return '+'; }
"-"  { return '-'; }
"*"  { return '*'; }
"/"  { return '/'; }
"!" { return '!'; } 
[ \t] ;
\n { yylineno++; }
. { return yytext[0]; }

%%