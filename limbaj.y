%code requires {
  #include <string>
  #include <vector>
  using namespace std;
}

%{
#include <iostream>
#include <string>
#include <vector>
#include "SymTable.h"

// Declaram externalele necesare
extern int yylex();
void yyerror(const char * s);
extern SymTable* current; // Pointerul catre tabela curenta (definit in main.cpp)

// Helper pentru formatare erori
void reportError(const char* fmt, string s1, string s2 = "") {
    char msg[200];
    sprintf(msg, fmt, s1.c_str(), s2.c_str());
    yyerror(msg);
}
%}

%union {
     std::string* strVal;
     std::vector<std::string>* argsVal; // Atribut pentru liste de parametri
}

%left OR
%left AND
%left EQ NEQ
%left LT LE GT GE
%left '+' '-' 
%left '*' '/'
%left DOT 

%token BGIN END ASSIGN NR NR_FLOAT PRINT CLASS IF WHILE CHAR STRING ELSE
%token<strVal> ID TYPE BOOL_VAL 
%type<strVal> token_id expression 
%type<strVal> func_header class_header param
%type<argsVal> call_list list_param 

%start progr

%%

progr : global_definitions main_block 
        { std::cout << "The program is correct!" << std::endl; }
      ;

global_definitions : /* empty */
                   | global_definitions global_def
                   ;

global_def : class_definition
           | function_definition
           | global_var_definition
           ;

/* --- CLASE --- */
class_header : CLASS token_id 
             { 
                 current->addClass(*$2);
                 SymTable* newScope = new SymTable("class_" + *$2, current);
                 SymTable::addClassScope(*$2, newScope);
                 current = newScope;
                 $$ = $2; 
             }
             ;

class_definition : class_header '{' declarations '}' ';' 
                 { 
                     current->printTableToFile("tables.txt");
                     current = current->getParent();
                 }
                 ;

/* --- DECLARATII SI FUNCTII --- */

/* func_header creeaza scope-ul SI returneaza numele functiei */
func_header : TYPE token_id '(' 
            {
                 current->addFunc(*$1, *$2);
                 current = new SymTable("func_" + *$2, current);
                 $$ = $2; 
            }
            ;

declarations : decl
             | declarations decl
             | function_definition
             | declarations function_definition
             ;

global_var_definition : decl ;

decl : TYPE token_id ';' 
       { 
           if(!current->addVar(*$1, *$2)) reportError("Variable '%s' already defined", *$2);
           delete $1; delete $2;
       }
     | ID ID ';' // Declarare obiect clasa
       {
           if(SymTable::getClassScope(*$1)) {
               if(!current->addVar(*$1, *$2)) reportError("Variable '%s' already defined", *$2);
               delete $1; delete $2;
           } else {
               reportError("Type '%s' is not defined", *$1);
           }
       }
     /* Prototipuri */
     | func_header list_param ')' ';' 
       {
           current->getParent()->updateFuncParams(*$1, *$2);
           delete $2; 
           current = current->getParent(); 
       }
     | func_header ')' ';' 
       {
           current->getParent()->updateFuncParams(*$1, vector<string>());
           current = current->getParent();
       }
     ;

/* Regula simpla pentru un parametru: il adauga in SymTable si returneaza tipul string */
param : TYPE token_id 
      {
           if(!current->addVar(*$1, *$2)) reportError("Parameter '%s' already defined", *$2);
           $$ = new string(*$1); // Returnam tipul pentru a fi colectat in lista
           delete $1; delete $2;
      }
      ;

/* Construim vectorul de tipuri folosind regula param */
list_param : param 
           { 
             $$ = new vector<string>(); 
             $$->push_back(*$1); 
             delete $1;
           }
           | list_param ',' param 
           { 
             $$ = $1; 
             $$->push_back(*$3); 
             delete $3;
           }
           ;


/* DEFINITIA FUNCTIEI */
function_definition : func_header list_param ')' '{' 
                    {
                        current->getParent()->updateFuncParams(*$1, *$2);
                        delete $2;
                    }
                    func_body '}'
                    {
                        current->printTableToFile("tables.txt");
                        current = current->getParent();
                    }
                    | func_header ')' '{' 
                    {
                        current->getParent()->updateFuncParams(*$1, vector<string>());
                    }
                    func_body '}'
                    {
                        current->printTableToFile("tables.txt");
                        current = current->getParent();
                    }
                    ;

func_body : statement_list
          | local_declarations statement_list
          ;

local_declarations : decl | local_declarations decl ;

main_block : BGIN statement_list END ;

statement_list : statement ';' 
               | statement_list statement ';' 
               ;

if_check : IF '(' expression ')' 
         { if (*$3 != "bool") yyerror("IF condition must be bool!"); delete $3; }
         ;

while_check : WHILE '(' expression ')' 
            { if (*$3 != "bool") yyerror("WHILE condition must be bool!"); delete $3; }
            ;

statement : ID ASSIGN expression
          {
              string varType = current->getType(*$1);
              if(varType == "") reportError("Variable '%s' not defined", *$1);
              else if (varType != *$3 && *$3 != "error") reportError("Cannot assign '%s' to '%s'", *$3, varType);
              delete $1; delete $3;
          }
          | token_id DOT token_id ASSIGN expression  
          {
               string res = current->getMemberType(*$1, *$3);
               if (res == "error_undef") reportError("Object '%s' not defined", *$1);
               else if (res == "error_not_class") reportError("Variable '%s' is not an object", *$1);
               else if (res == "error_member_missing") reportError("Member '%s' not found", *$3);
               else if (res != *$5 && *$5 != "error") reportError("Type mismatch on member assignment: expected '%s', got '%s'", res, *$5);
               delete $1; delete $3; delete $5;
          }
          | token_id '(' call_list ')'     
          {
              vector<string> expected = current->getFuncParams(*$1);
              vector<string>* given = $3;
              if (expected.size() != given->size()) reportError("Function '%s' arg count mismatch", *$1);
              else {
                  for(size_t i=0; i<expected.size(); ++i) 
                      if(expected[i] != (*given)[i]) reportError("Arg %d type mismatch", to_string(i+1));
              }
              delete $1; delete $3;
          }
          | token_id '(' ')'
          {
               if(current->getFuncParams(*$1).size() != 0) reportError("Function '%s' expects arguments", *$1);
               delete $1;
          }
          | if_check '{' statement_list '}' ELSE statement
          | if_check '{' statement_list '}' 
          | while_check '{' statement_list '}'
          | PRINT '(' expression ')' { delete $3; }
          ;

call_list : expression 
          { 
              $$ = new vector<string>(); 
              $$->push_back(*$1); delete $1;
          }
          | call_list ',' expression 
          { 
              $$ = $1; 
              $$->push_back(*$3); delete $3;
          }
          ;

token_id : ID ;

expression : expression '+' expression
             {
                 if (SymTable::checkTypeCompatibility(*$1, *$3, "+")) $$ = new string(*$1);
                 else { yyerror("Type mismatch in +"); $$ = new string("error"); }
                 delete $1; delete $3;
             }
           | expression '-' expression
             {
                 if (SymTable::checkTypeCompatibility(*$1, *$3, "-")) $$ = new string(*$1);
                 else { yyerror("Type mismatch in -"); $$ = new string("error"); }
                 delete $1; delete $3;
             }
           | expression '*' expression
             {
                  if (SymTable::checkTypeCompatibility(*$1, *$3, "*")) $$ = new string(*$1);
                  else { yyerror("Type mismatch in *"); $$ = new string("error"); }
                  delete $1; delete $3;
             }
           | expression '/' expression
             {
                 if (SymTable::checkTypeCompatibility(*$1, *$3, "/")) $$ = new string(*$1);
                 else { yyerror("Type mismatch in /"); $$ = new string("error"); }
                 delete $1; delete $3;
             }
           | '(' expression ')' { $$ = $2; }
           
           | expression AND expression
             {
                 if (SymTable::checkTypeCompatibility(*$1, *$3, "&&")) $$ = new string("bool");
                 else { yyerror("&& requires bool"); $$ = new string("error"); }
                 delete $1; delete $3;
             }
           | expression OR expression
             {
                 if (SymTable::checkTypeCompatibility(*$1, *$3, "||")) $$ = new string("bool");
                 else { yyerror("|| requires bool"); $$ = new string("error"); }
                 delete $1; delete $3;
             }
           | expression EQ expression
             {
                 if (SymTable::checkTypeCompatibility(*$1, *$3, "==")) $$ = new string("bool");
                 else { yyerror("Type mismatch in =="); $$ = new string("error"); }
                 delete $1; delete $3;
             }
           | expression NEQ expression 
             { if (SymTable::checkTypeCompatibility(*$1, *$3, "!=")) $$ = new string("bool"); else $$=new string("error"); delete $1; delete $3; }
           | expression LT expression 
             { if (SymTable::checkTypeCompatibility(*$1, *$3, "<")) $$ = new string("bool"); else $$=new string("error"); delete $1; delete $3; }
           | expression LE expression 
             { if (SymTable::checkTypeCompatibility(*$1, *$3, "<=")) $$ = new string("bool"); else $$=new string("error"); delete $1; delete $3; }
           | expression GT expression 
             { if (SymTable::checkTypeCompatibility(*$1, *$3, ">")) $$ = new string("bool"); else $$=new string("error"); delete $1; delete $3; }
           | expression GE expression 
             { if (SymTable::checkTypeCompatibility(*$1, *$3, ">=")) $$ = new string("bool"); else $$=new string("error"); delete $1; delete $3; }

           | NR       { $$ = new string("int"); }
           | NR_FLOAT { $$ = new string("float"); }
           | CHAR     { $$ = new string("char"); }
           | STRING   { $$ = new string("string"); }
           | BOOL_VAL { $$ = new string("bool"); }
           
           | ID 
             {
                 string type = current->getType(*$1);
                 if (type == "") { reportError("Var '%s' undefined", *$1); $$ = new string("error"); } 
                 else { $$ = new string(type); }
                 delete $1;
             }
           | token_id DOT token_id 
             { 
                 string type = current->getMemberType(*$1, *$3);
                 if (type.find("error") != string::npos) { reportError("Member access error: %s", type); $$ = new string("error"); }
                 else $$ = new string(type);
                 delete $1; delete $3;
             }
           | token_id '(' call_list ')' 
             { 
                 string retType = current->getType(*$1);
                 if(retType == "") { reportError("Func '%s' undefined", *$1); $$ = new string("error"); }
                 else {
                     // Check args
                     vector<string> expected = current->getFuncParams(*$1);
                     if(expected.size() != $3->size()) yyerror("Arg count mismatch");
                     // Simplificare check
                     $$ = new string(retType);
                 }
                 delete $1; delete $3;
             }
           | token_id '(' ')'
             {
                 string retType = current->getType(*$1);
                 if(retType == "") { reportError("Func '%s' undefined", *$1); $$ = new string("error"); }
                 else $$ = new string(retType);
                 delete $1;
             }
           ;
%%