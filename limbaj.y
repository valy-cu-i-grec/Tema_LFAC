%code requires {
  #include <string>
  using namespace std;
}

%{
#include <iostream>
#include "SymTable.h"
extern FILE* yyin;
extern char* yytext;
extern int yylineno;
extern int yylex();
void yyerror(const char * s);
class SymTable* current;
int errorCount = 0;
%}

%union {
     std::string* Str;
}

/* PRIORITATI OPERATORI */
%left OR
%left AND
%left EQ NEQ
%left LT LE GT GE
%left '+' '-' 
%left '*' '/'
%left DOT 

/* TOKENI */
%token BGIN END ASSIGN NR NR_FLOAT PRINT CLASS IF WHILE CHAR STRING ELSE
%token<Str> ID TYPE BOOL_VAL ID_ARITH ID_BOOL 
%type<Str> token_id

%start progr

%%

/* --- STRUCTURA PROGRAM --- */
progr : global_definitions main_block 
        { 
            if (errorCount == 0) cout<< "The program is correct!" << endl; 
        }
      ;

global_definitions : /* empty */
                   | global_definitions global_def
                   ;

global_def : class_definition
           | function_definition
           | global_var_definition
           ;

/* --- DECLARATII --- */
class_definition : CLASS token_id '{' declarations '}' ';'
                   { current->addClass($2); }
                 ;

declarations : decl
             | declarations decl
             | function_definition
             | declarations function_definition
             ;

global_var_definition : decl ;

decl : TYPE token_id ';' 
       { 
           if(!current->existsId($2)) {
               current->addVar($1,$2);
               delete $1; delete $2;
           } else {
               errorCount++; 
               yyerror("Variable already defined");
           }
       }
     | TYPE token_id '(' list_param ')' ';' 
     | ID ID ';'
       {
           if(current->existsClass($1)) {
               if(!current->existsId($2)) {
                   current->addVar($1, $2);
                   delete $1; delete $2;
               } else {
                   errorCount++; yyerror("Variable already defined");
               }
           } else {
               errorCount++; 
               char msg[100]; sprintf(msg, "Type '%s' is not defined", $1->c_str()); yyerror(msg);
           }
       }
     ;

list_param : param | list_param ',' param ;

param : TYPE token_id 
      { 
           if(!current->existsId($2)) { current->addVar($1,$2); delete $1; delete $2; }
           else { errorCount++; yyerror("Variable already defined!"); }
      }
      ; 

function_definition : TYPE token_id '(' list_param ')' '{' func_body '}' ;

func_body : statement_list
          | local_declarations statement_list
          ;

local_declarations : decl | local_declarations decl ;

main_block : BGIN statement_list END ;

/* --- INSTRUCTIUNI --- */
statement_list : statement ';' | statement_list statement ';' ;

statement : token_id ASSIGN expression
          | token_id DOT token_id ASSIGN expression  /* Permite obj.x := ... */
          | token_id '(' call_list ')'     
          | token_id '(' ')'
          | IF '(' expression ')' '{' statement_list '}' ELSE statement
          | WHILE '(' expression ')' '{' statement_list '}'
          | PRINT '(' expression ')'
          ;

call_list : expression | call_list ',' expression ;

/* --- EXPRESII UNIFICATE --- */
/* Rezolva conflictele generate de lexerul care intoarce ID_ARITH/ID_BOOL */
token_id : ID | ID_ARITH | ID_BOOL ;

expression : expression '+' expression
           | expression '-' expression
           | expression '*' expression
           | expression '/' expression
           | '(' expression ')'
           | expression AND expression
           | expression OR expression
           | expression EQ expression
           | expression NEQ expression
           | expression LT expression
           | expression LE expression
           | expression GT expression
           | expression GE expression
           | NR | NR_FLOAT | CHAR | STRING | BOOL_VAL
           | token_id
           | token_id DOT token_id
           | token_id '(' call_list ')'
           | token_id '(' ')'
           ;

%%
void yyerror(const char * s){
     cout << "error: " << s << " at line: " << yylineno << endl;
}

int main(int argc, char** argv){
     if(argc > 1) yyin=fopen(argv[1],"r");
     else yyin = stdin;
     current = new SymTable("global");
     yyparse();
     cout << "Variables:" <<endl;
     current->printVars();
     delete current;
}