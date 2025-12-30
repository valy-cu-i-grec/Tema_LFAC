%{
#include <iostream>
#include <fstream>
#include <string>
#include <map>
#include "SymTable.h"

extern FILE* yyin;
extern char* yytext;
extern int yylineno;
extern int yylex();
void yyerror(const char * s);

class SymTable* current;
std::map<std::string, SymTable*> classScopes;
int errorCount = 0;

// Functie auxiliara
bool is_numeric(string type) {
    return type == "int" || type == "float";
}
%}

%union {
     std::string* Str;
}

%left OR
%left AND
%left EQ NEQ
%left LT LE GT GE
%left '+' '-' 
%left '*' '/'
%left DOT 

%token BGIN END ASSIGN NR NR_FLOAT PRINT CLASS IF WHILE CHAR STRING ELSE
%token<Str> ID TYPE BOOL_VAL 
%type<Str> token_id expression call_list

%start progr

%%

progr : global_definitions main_block 
        { 
            if (errorCount == 0) cout<< "The program is correct!" << endl; 
            current->printTableToFile("tables.txt");
        }
      ;

global_definitions :
                   | global_definitions global_def
                   ;

global_def : class_definition
           | function_definition
           | global_var_definition
           ;

/* --- CLASE --- */
class_header : CLASS token_id 
             { 
                 current->addClass($2);
                 string className = *$2;
                 SymTable* newScope = new SymTable("class_" + className, current);
                 classScopes[className] = newScope;
                 current = newScope;
             }
             ;

class_definition : class_header '{' declarations '}' ';' 
                 { 
                     current->printTableToFile("tables.txt");
                     current = current->getParent();
                 }
                 ;

/* --- DECLARATII SI FUNCTII --- */
/* Regula comuna pentru antetul functiei (prototip sau definitie) */
/* Aceasta regula creeaza automat scopul nou */
func_header : TYPE token_id '(' 
            {
                 current->addFunc($1, $2);
                 current = new SymTable("func_" + *$2, current);
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
           if(!current->existsId($2)) {
               current->addVar($1, $2);
               delete $1; delete $2;
           } else {
               errorCount++;
               yyerror("Variable already defined");
           }
       }
     | ID ID ';'
       {
           if(current->existsClass($1)) {
               if(!current->existsId($2)) {
                   current->addVar($1, $2);
                   delete $1; delete $2;
               } else {
                   errorCount++;
                   yyerror("Variable already defined");
               }
           } else {
               errorCount++;
               char msg[100]; sprintf(msg, "Type '%s' is not defined", $1->c_str()); yyerror(msg);
           }
       }
     /* PROTOTIPURI DE FUNCTII (folosind func_header) */
     | func_header list_param ')' ';' 
       {
           // Doar am declarat, deci iesim din scopul creat de func_header
           current = current->getParent();
       }
     | func_header ')' ';' 
       {
           current = current->getParent();
       }
     ;

list_param : param 
           | list_param ',' param 
           ;

param : TYPE token_id 
      { 
           if(!current->existsId($2)) { 
               current->addVar($1, $2);
               delete $1; delete $2; 
           } else { 
               errorCount++; 
               yyerror("Variable already defined!"); 
           }
      }
      ;

/* DEFINITIA FUNCTIEI (folosind func_header) */
function_definition : func_header list_param ')' '{' func_body '}'
                    {
                        current->printTableToFile("tables.txt");
                        current = current->getParent();
                    }
                    | func_header ')' '{' func_body '}'
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

/* --- REGULI AJUTATOARE PENTRU IF/WHILE (evita conflictele) --- */
if_check : IF '(' expression ')' 
         {
             if (*$3 != "bool") { errorCount++; yyerror("IF condition must be bool!"); }
         }
         ;

while_check : WHILE '(' expression ')' 
            {
                if (*$3 != "bool") { errorCount++; yyerror("WHILE condition must be bool!"); }
            }
            ;

statement : ID ASSIGN expression
          {
              string varType = current->getType($1);
              if(varType == "") { errorCount++; yyerror("Variable not defined!"); }
              else if (varType != *$3) {
                  errorCount++;
                  char msg[100]; sprintf(msg, "Type mismatch. Cannot assign '%s' to '%s'", $3->c_str(), varType.c_str());
                  yyerror(msg);
              }
          }
          | token_id DOT token_id ASSIGN expression  
          {
               string objName = *$1;
               string memName = *$3;
               string objType = current->getType(&objName); 

               if (classScopes.find(objType) != classScopes.end()) {
                   SymTable* clsTable = classScopes[objType];
                   string memType = clsTable->getType(&memName);
                   
                   if (memType == "") { errorCount++; yyerror("Member not found"); } 
                   else if (memType != *$5) { errorCount++; yyerror("Type mismatch in member assignment"); }
               } else {
                   errorCount++; yyerror("Invalid object or class access");
               }
          }
          | token_id '(' call_list ')'     
          | token_id '(' ')'
          /* Folosim regulile factorizate if_check / while_check */
          | if_check '{' statement_list '}' ELSE statement
          | if_check '{' statement_list '}' 
          | while_check '{' statement_list '}'
          | PRINT '(' expression ')'
          ;

call_list : expression 
          | call_list ',' expression 
          ;

token_id : ID ;

expression : expression '+' expression
             {
                 if (is_numeric(*$1) && is_numeric(*$3)) {
                     if (*$1 == "float" || *$3 == "float") $$ = new string("float");
                     else $$ = new string("int");
                 } else { errorCount++; yyerror("Invalid operands for +"); $$ = new string("error"); }
             }
           | expression '-' expression
             {
                 if (is_numeric(*$1) && is_numeric(*$3)) {
                      if (*$1 == "float" || *$3 == "float") $$ = new string("float");
                      else $$ = new string("int");
                 } else { errorCount++; yyerror("Invalid operands for -"); $$ = new string("error"); }
             }
           | expression '*' expression
             {
                  if (is_numeric(*$1) && is_numeric(*$3)) {
                      if (*$1 == "float" || *$3 == "float") $$ = new string("float");
                      else $$ = new string("int");
                 } else { errorCount++; yyerror("Invalid operands for *"); $$ = new string("error"); }
             }
           | expression '/' expression
             {
                 if (is_numeric(*$1) && is_numeric(*$3)) $$ = new string("float");
                 else { errorCount++; yyerror("Invalid operands for /"); $$ = new string("error"); }
             }
           | '(' expression ')' { $$ = $2; }
           
           | expression AND expression
             {
                 if (*$1 == "bool" && *$3 == "bool") $$ = new string("bool");
                 else { errorCount++; yyerror("&& requires bool"); $$ = new string("error"); }
             }
           | expression OR expression
             {
                 if (*$1 == "bool" && *$3 == "bool") $$ = new string("bool");
                 else { errorCount++; yyerror("|| requires bool"); $$ = new string("error"); }
             }
           | expression EQ expression
             {
                 if (*$1 == *$3) $$ = new string("bool");
                 else { errorCount++; yyerror("Cannot compare different types"); $$ = new string("error"); }
             }
           | expression NEQ expression { if(*$1 == *$3) $$ = new string("bool"); else $$ = new string("error"); }
           | expression LT expression { if(is_numeric(*$1) && is_numeric(*$3)) $$ = new string("bool"); else $$ = new string("error"); }
           | expression LE expression { if(is_numeric(*$1) && is_numeric(*$3)) $$ = new string("bool"); else $$ = new string("error"); }
           | expression GT expression { if(is_numeric(*$1) && is_numeric(*$3)) $$ = new string("bool"); else $$ = new string("error"); }
           | expression GE expression { if(is_numeric(*$1) && is_numeric(*$3)) $$ = new string("bool"); else $$ = new string("error"); }

           | NR       { $$ = new string("int"); }
           | NR_FLOAT { $$ = new string("float"); }
           | CHAR     { $$ = new string("char"); }
           | STRING   { $$ = new string("string"); }
           | BOOL_VAL { $$ = new string("bool"); }
           
           | ID 
             {
                 string type = current->getType($1);
                 if (type == "") { $$ = new string("error"); } 
                 else { $$ = new string(type); }
             }
           | token_id DOT token_id 
             { 
                 string objName = *$1;
                 string memName = *$3;
                 string objType = current->getType(&objName);
                 
                 if (classScopes.find(objType) != classScopes.end()) {
                     SymTable* clsTable = classScopes[objType];
                     string memType = clsTable->getType(&memName);
                     if (memType != "") $$ = new string(memType);
                     else { errorCount++; yyerror("Member not found"); $$ = new string("error"); }
                 } else {
                     errorCount++; yyerror("Accessing member of unknown type");
                     $$ = new string("error");
                 }
             }
           | token_id '(' call_list ')' 
             { 
                 string funcType = current->getType($1);
                 if(funcType != "") $$ = new string(funcType);
                 else $$ = new string("unknown");
             }
           | token_id '(' ')'
             {
                 string funcType = current->getType($1);
                 if(funcType != "") $$ = new string(funcType);
                 else $$ = new string("unknown");
             }
           ;

%%

void yyerror(const char * s){
     cout << "error: " << s << " at line: " << yylineno << endl;
}

int main(int argc, char** argv){
     std::ofstream file("tables.txt");
     file.close();

     if(argc > 1) yyin=fopen(argv[1],"r");
     else yyin = stdin;
     
     current = new SymTable("global");
     yyparse();
     
     current->printTableToFile("tables.txt");
     delete current;
}