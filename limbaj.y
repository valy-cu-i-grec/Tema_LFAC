
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

//%destructor { delete $$; } <Str> 

%left '+' '-' 
%left '*'

%token  BGIN END ASSIGN NR NR_FLOAT
%token<Str> ID TYPE
%start progr
%%
progr :  declarations main {if (errorCount == 0) cout<< "The program is correct!" << endl;}
      ;

declarations : decl           
	      |  declarations decl    
	      ;

decl       :  TYPE ID ';' { 
                              if(!current->existsId($2)) {
                                    current->addVar($1,$2);
                                    delete $1;
                                    delete $2;
                              } else {
                                   errorCount++; 
                                   yyerror("Variable already defined");
                              }
                          }
              | TYPE ID  '(' list_param ')' ';'
           ;

list_param : param
            | list_param ','  param 
            ;
            
param : TYPE ID 
      ; 
      

main : BGIN list END  
     ;
     

list :  statement ';' 
     | list statement ';'
     ;

statement: ID ASSIGN e 
         | ID '(' call_list ')'
         ;

e : e '+' e   
  | e '*' e   
  |'(' e ')' 
  | NR 
  | NR_FLOAT
  | ID
  ;
  
        
call_list : NR
           | call_list ',' NR
           ;
%%
void yyerror(const char * s){
     cout << "error:" << s << " at line: " << yylineno << endl;
}

int main(int argc, char** argv){
     yyin=fopen(argv[1],"r");
     current = new SymTable("global");
     yyparse();
     cout << "Variables:" <<endl;
     current->printVars();
     delete current;
} 