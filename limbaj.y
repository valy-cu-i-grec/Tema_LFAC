
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


%left OR
%left AND
%left EQ NEQ
%left LT LE GT GE
%left '+' '-' 
%left '*'

%token  BGIN END ASSIGN NR NR_FLOAT PRINT CLASS DOT IF WHILE
%token<Str> ID TYPE BOOL_VAL ID_ARITH ID_BOOL 
%type<Str> token_id
%start progr
%%
progr :  declarations main {if (errorCount == 0) cout<< "The program is correct!" << endl;}
      ;

declarations : decl           
	      | declarations decl  
           | class_declaration
           | declarations class_declaration
           | function_declaration
           | declarations function_declaration
	      ;

class_declaration : CLASS token_id '{' declarations '}' ';'
                    {
                         current->addClass($2);
                    }
                  ;

function_declaration : TYPE token_id '(' list_param ')' '{' func_body '}'
                    ;

func_body :list
          | local_declaration list
          ;

local_declaration : decl
                  | local_declaration decl

decl       :  TYPE token_id ';' { 
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
              | ID ID ';'
              {
               if(current->existsClass($1))
              {
               if(!current->existsId($2))
               {
                    current->addVar($1, $2);
                    delete $1; delete $2;
               }
               else
               {
                    errorCount++;
                    yyerror("Variable already defined");
               }
              }
              else
              {
               errorCount++;
               char msg[100];
               sprintf(msg, "Type '%s' is not defined (it is not a class)", $1->c_str());
               yyerror(msg);
              }
              }
           ;

list_param : param
            | list_param ','  param 
            ;

param : TYPE token_id { 
     if(!current->existsId($2))
     {
          current->addVar($1,$2);
          delete $1; delete $2;
     }
     else
     {
          errorCount++;
          yyerror("Variable already defined!");
     }
}
      ; 
      

main : BGIN list END  
     ;
     

list :  statement ';' 
     | list statement ';'
     ;

token_id : ID
          | ID_ARITH
          | ID_BOOL

e_arith : e_arith '+' e_arith
        | e_arith '-' e_arith
        | e_arith '*' e_arith
        | '(' e_arith ')'
        | NR
        | NR_FLOAT
        | ID_ARITH            
        | ID_ARITH DOT ID    
        ;

e_logic : e_logic AND e_logic
        | e_logic OR e_logic
        | '(' e_logic ')'
        | BOOL_VAL
        | ID_BOOL            
        | ID_BOOL DOT ID
        | e_arith EQ e_arith
        | e_arith LT e_arith
        | e_arith LE e_arith
        | e_arith NEQ e_arith
        | e_arith GT e_arith
        | e_arith GE e_arith
        ;

statement : ID_ARITH ASSIGN e_arith  
          | ID_BOOL ASSIGN e_logic  
          | IF '(' e_logic ')' '{' list '}' 
          | WHILE '(' e_logic ')' '{' list '}'
          | PRINT '(' e_arith ')'
          | PRINT '(' e_logic ')'
          ;

call_list : e_arith
          | call_list ',' e_arith
          | e_logic
          | call_list ',' e_logic
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

