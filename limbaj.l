%{
#include <stdio.h>
#include <string>
#include "limbaj.tab.h"
#include "SymTable.h"

extern SymTable* current;
%}

%option noyywrap

%%

"int"|"float"|"char"|"string"|"bool" { yylval.Str = new std::string(yytext); return TYPE; }
"begin_progr" { return BGIN; }
"end_progr"   { return END; }
"true"|"false" { yylval.Str = new std::string(yytext); return BOOL_VAL; }
"Print"       { return PRINT; }
"class"       { return CLASS; }
"."           { return DOT; }
"if"          { return IF; }
"else"        {return ELSE;}
"while"       { return WHILE; }

\"[a-zA-Z0-9 ]*\" { 
    yylval.Str = new std::string(yytext);
    return STRING;
}

\'[a-zA-Z0-9]\' {
    yylval.Str = new std::string(yytext);
    return CHAR;
}

[a-zA-Z][a-zA-Z0-9]* {
    yylval.Str = new std::string(yytext);
    
    if(current != NULL)
    {
        /* Verificam daca variabila exista deja in tabela de simboluri */
        /* Nota: Asta poate returna ID_ARITH pentru o variabila int, chiar daca e folosita ca membru al unei clase */
        std::string type = current->getType(yylval.Str);

        if(type == "int" || type == "float" || type == "string" || type == "char")
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

":=" { return ASSIGN; }

[1-9]+[0-9]*|0 { 
    yylval.Str = new std::string(yytext); /* IMPORTANT: Salvam valoarea pt parser */
    return NR; 
}

[0-9]+[.][0-9]+ { 
    yylval.Str = new std::string(yytext); /* IMPORTANT: Salvam valoarea pt parser */
    return NR_FLOAT; 
}

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

[ \t] ;
\n { yylineno++; }
. { return yytext[0]; }

%%