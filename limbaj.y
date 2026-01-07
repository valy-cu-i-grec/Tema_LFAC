%code requires {
  #include <string>
  #include <vector>
  #include "ASTNode.h"
  #include "Value.h"
  // Nu includem SymTable aici pentru a evita recursivitatea la compilare
}

%{
#include <iostream>
#include <stdio.h>
#include "SymTable.h"
using namespace std; // 2. ASIGURĂ-TE CĂ ASTA E AICI pentru string

extern int yylex();
void yyerror(const char * s);
extern SymTable* current; 

// 3. FOLOSESTE std::string EXPLICIT SAU ASIGURĂ-TE CĂ using namespace std e deasupra
void reportError(const char* fmt, std::string s1, std::string s2 = "") {
    char msg[200];
    sprintf(msg, fmt, s1.c_str(), s2.c_str());
    yyerror(msg);
}
%}

%union {
     std::string* strVal;
     std::vector<std::string>* argsVal; // Atribut pentru liste de parametri
     ASTNode* nodeVal;
}

%left OR
%left AND
%left EQ NEQ
%left LT LE GT GE
%left '+' '-' 
%left '*' '/'
%left DOT 
%right '!'

%token BGIN END ASSIGN PRINT CLASS IF WHILE ELSE RETURN
%token<strVal> ID TYPE BOOL_VAL NR NR_FLOAT STRING CHAR
%type<strVal> token_id
%type<nodeVal> expression statement statement_list
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
                 current->setExpectedReturnType(*$1); // Setăm tipul în noul scope
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
               { 
                   if ($1 != nullptr) {
                       $1->eval(current); 
                       // Opțional: delete $1; (dacă vrei să cureți memoria după execuție)
                    delete $1;
                   }
                   $$ = nullptr;
               }
               | statement_list statement ';' 
               { 
                   if ($2 != nullptr) {
                       $2->eval(current);
                       delete $2;
                   }
                   $$ = nullptr;
               }
               ;
if_check : IF '(' expression ')' 
         { 
             if ($3->type != "bool" && $3->type != "error") 
                 yyerror("IF condition must be bool!"); 
             // IMPORTANT: Ștergem nodul aici pentru că structurile de control 
             // returnează NULL AST conform cerinței.
             delete $3; 
         }
         ;

while_check : WHILE '(' expression ')' 
            { 
                if ($3->type != "bool" && $3->type != "error") 
                    yyerror("WHILE condition must be bool!"); 
                delete $3; 
            }
            ;

statement : ID ASSIGN expression
         {
              string varType = current->getType(*$1);
              if(varType == "") {
                  reportError("Variable '%s' not defined", *$1);
                  $$ = nullptr;
              } 
              else {
                  // Verificăm compatibilitatea tipurilor înainte de a crea nodul
                  if (SymTable::checkTypeCompatibility(varType, $3->type, ":=")) {
                      // Creăm un nod pentru ID (frunză)
                      ASTNode* idNode = new ASTNode(*$1, varType);
                      idNode->root = *$1; // Ne asigurăm că root e numele variabilei
                      
                      // Creăm nodul rădăcină ":="
                      $$ = new ASTNode(":=", varType, idNode, $3);
                  } else {
                      reportError("Cannot assign %s to %s", $3->type, varType);
                      $$ = nullptr; 
                  }
              }
              delete $1;
          }
          | token_id DOT token_id ASSIGN expression  
          {
               // 1. Verificăm tipul membrului în tabela de simboluri
               string res = current->getMemberType(*$1, *$3);

               // 2. Raportăm erorile specifice (codul tău original)
               if (res == "error_undef") 
                   reportError("Object '%s' not defined", *$1);
               else if (res == "error_not_class") 
                   reportError("Variable '%s' is not an object", *$1);
               else if (res == "error_member_missing") 
                   reportError("Member '%s' not found", *$3);
               
               // 3. Verificarea compatibilității de tip
               // ATENȚIE: $5 este ASTNode*, deci folosim $5->type
               else if (!SymTable::checkTypeCompatibility(res, $5->type, ":=")) {
                   reportError("Type mismatch on member assignment: expected '%s', got '%s'", res, $5->type);
               }

               delete $1; 
               delete $3;
               delete $5;
               // 4. Conform cerinței: Returnăm NULL pentru acest tip de statement
               $$ = nullptr;

               // 5. Curățăm memoria pentru string-urile numelor
               // Notă: Nu ștergem $5 (expresia) aici deoarece destructorul 
               // s-ar putea să fie apelat mai târziu sau ar putea genera erori
               // dacă este un nod complex. Totuși, fiind un statement orfan (nu e în AST),
               // un "delete $5" ar preveni memory leaks.
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
              $$ = nullptr;
          }
          | token_id '(' ')'
          {
               if(current->getFuncParams(*$1).size() != 0) reportError("Function '%s' expects arguments", *$1);
               delete $1;
               $$ = nullptr;
          }
          | token_id DOT token_id '(' call_list ')'
          {
              // 1. Verificăm dacă membrul este o funcție în interiorul clasei obiectului
              // Folosim o logică similară cu getMemberType
              string resType = current->getMemberType(*$1, *$3);
              
              if (resType.find("error") != string::npos) {
                  reportError("Method access error: %s", resType);
              } else {
                  // Aici ar trebui să verifici și parametrii (similar cu funcțiile globale)
                  // Pentru simplitate în acest stadiu, verificăm doar existența
              }
              
              delete $1; delete $3; delete $5;
              $$ = nullptr; 
          }
          | token_id DOT token_id '(' ')'
          {
              string resType = current->getMemberType(*$1, *$3);
              if (resType.find("error") != string::npos) {
                  reportError("Method access error: %s", resType);
              }
              delete $1; delete $3;
              $$ = nullptr;
          }
          | if_check '{' statement_list '}' ELSE '{' statement_list '}' {$$ = nullptr;}
          | if_check '{' statement_list '}' {$$ = nullptr;}
          | while_check '{' statement_list '}' {$$ = nullptr;}
          | PRINT '(' expression ')' 
          { 
              // Creăm nodul PRINT care are expresia ca fiu stâng
              $$ = new ASTNode("PRINT", $3->type, $3); 
          }
          |RETURN expression
          {
              std::string expected = current->getExpectedReturnType();
              
              if (expected == "") {
                  reportError("Return statement outside of any function", "");
              } 
              else if (!SymTable::checkTypeCompatibility(expected, $2->type, "return")) {
                  reportError("Return type mismatch: expected %s, got %s", expected, $2->type);
              }
              
              // Pentru moment, return nu generează un nod în AST care să oprească execuția,
              // el doar verifică validitatea semantică a codului.
              $$ = nullptr; 
              delete $2;
          }
          ;

call_list : expression 
          { 
              $$ = new vector<string>(); 
              $$->push_back($1->type); // Extragem tipul din nodul AST
              delete $1; // Distrugem nodul, nu avem nevoie de el pentru check-ul semnăturii
          }
          | call_list ',' expression 
          { 
              $$ = $1; 
              $$->push_back($3->type); 
              delete $3;
          }
          ;

token_id : ID ;

expression : expression '+' expression
             {
                 /*if (SymTable::checkTypeCompatibility(*$1, *$3, "+")) $$ = new string(*$1);
                 else { yyerror("Type mismatch in +"); $$ = new string("error"); }
                 delete $1; delete $3;
              */
             if(SymTable::checkTypeCompatibility($1->type, $3->type, "+"))
             {
              $$ = new ASTNode("+", $1->type, $1, $3);
             }
             else
             {
              yyerror("Type mismatch in +");
              $$ = ASTNode::createOther("error");
             }

             }
           | expression '-' expression
             {

              if(SymTable::checkTypeCompatibility($1->type, $3->type, "-"))
             {
              $$ = new ASTNode("-", $1->type, $1, $3);
             }
             else
             {
              yyerror("Type mismatch in -");
              $$ = ASTNode::createOther("error");
             }

             }
           | expression '*' expression
             {

              if(SymTable::checkTypeCompatibility($1->type, $3->type, "*"))
             {
              $$ = new ASTNode("*", $1->type, $1, $3);
             }
             else
             {
              yyerror("Type mismatch in *");
              $$ = ASTNode::createOther("error");
             }

             }
           | expression '/' expression
             {
              if(SymTable::checkTypeCompatibility($1->type, $3->type, "/"))
             {
              $$ = new ASTNode("/", $1->type, $1, $3);
             }
             else
             {
              yyerror("Type mismatch in /");
              $$ = ASTNode::createOther("error");
             }

             }
             | '!' expression 
             { 
                $$ = new ASTNode("!", "bool", $2); 
             }
           | '(' expression ')' { $$ = $2; }
           | expression AND expression
             {
                 /*if (SymTable::checkTypeCompatibility(*$1, *$3, "&&")) $$ = new string("bool");
                 else { yyerror("&& requires bool"); $$ = new string("error"); }
                 delete $1; delete $3;
                 */

                if(SymTable::checkTypeCompatibility($1->type, $3->type, "&&"))
                {
                  $$ = new ASTNode("&&", "bool", $1, $3);
                }
                else
                {
                  yyerror("&& requires bool operands");
                  $$ = ASTNode::createOther("error");
                }

             }
           | expression OR expression
             {
              if(SymTable::checkTypeCompatibility($1->type, $3->type, "||"))
                {
                  $$ = new ASTNode("||", "bool", $1, $3);
                }
                else
                {
                  yyerror("|| requires bool operands");
                  $$ = ASTNode::createOther("error");
                }
             }
           | expression EQ expression
             {
               if(SymTable::checkTypeCompatibility($1->type, $3->type, "=="))
                {
                  $$ = new ASTNode("==", "bool", $1, $3);
                }
                else
                {
                  yyerror("== requires bool operands");
                  $$ = ASTNode::createOther("error");
                }
             }
          | expression NEQ expression 
             { 
                 if (SymTable::checkTypeCompatibility($1->type, $3->type, "!=")) 
                     $$ = new ASTNode("!=", "bool", $1, $3); 
                 else { yyerror("Type mismatch in !="); $$ = ASTNode::createOther("error"); }
             }
           | expression LT expression 
             { 
                 if (SymTable::checkTypeCompatibility($1->type, $3->type, "<")) 
                     $$ = new ASTNode("<", "bool", $1, $3); 
                 else { yyerror("Type mismatch in <"); $$ = ASTNode::createOther("error"); }
             }
           | expression LE expression 
             { 
                 if (SymTable::checkTypeCompatibility($1->type, $3->type, "<=")) 
                     $$ = new ASTNode("<=", "bool", $1, $3); 
                 else { yyerror("Type mismatch in <="); $$ = ASTNode::createOther("error"); }
             }
           | expression GT expression 
             { 
                 if (SymTable::checkTypeCompatibility($1->type, $3->type, ">")) 
                     $$ = new ASTNode(">", "bool", $1, $3); 
                 else { yyerror("Type mismatch in >"); $$ = ASTNode::createOther("error"); }
             }
           | expression GE expression 
             { 
                 if (SymTable::checkTypeCompatibility($1->type, $3->type, ">=")) 
                     $$ = new ASTNode(">=", "bool", $1, $3); 
                 else { yyerror("Type mismatch in >="); $$ = ASTNode::createOther("error"); }
             }
           | NR       { $$ = new ASTNode(Value(stoi(*$1)), "int"); delete $1; }
           | NR_FLOAT { $$ = new ASTNode(Value(stof(*$1)), "float"); delete $1; }
           | CHAR { 
                    // *$1 este ceva de genul "'a'"
                    // Luăm al doilea caracter (index 1) pentru a sări peste prima ghilimele
                    char actualChar = (*$1)[1]; 
    
                    // Folosim noul constructor Value(char)
                    $$ = new ASTNode(Value(actualChar), "char"); 
    
                    delete $1; 
                  }           
            | STRING   { 
             // Decupăm de la poziția 1, lungimea totală minus 2 ghilimele
             std::string content = $1->substr(1, $1->length() - 2);
             $$ = new ASTNode(Value(content), "string"); 
             delete $1; 
           } 
           | BOOL_VAL 
           { bool val = (*$1 == "true");
                 $$ = new ASTNode(Value(val), "bool"); 
                 delete $1;
           }
           
           | ID 
            { 
                if (current->getKind(*$1) == FUNCTION) {
                    reportError("Numele functiei '%s' nu poate fi folosit ca variabila", *$1);
                    $$ = ASTNode::createOther("error");
                } else {
                    string vType = current->getType(*$1);
                    if (vType == "") {
                        reportError("Variable '%s' undefined", *$1);
                        $$ = ASTNode::createOther("error");
                    } else {
                        $$ = new ASTNode(*$1, vType);
                    }
                }
                delete $1;
            }
           | token_id DOT token_id 
             { 
                 // 1. Apelăm logica ta de verificare din Symbol Table
                 string resType = current->getMemberType(*$1, *$3);

                 // 2. Verificăm dacă rezultatul este o eroare (exact cum făceai înainte)
                 if (resType.find("error") != string::npos) { 
                     reportError("Member access error: %s", resType); 
                     
                     // Returnăm un nod de eroare pentru a nu opri parserul, 
                     // dar semnalăm că tipul este invalid
                     $$ = ASTNode::createOther("error"); 
                 } 
                 else {
                     // 3. Dacă totul este OK, creăm nodul "OTHER" conform cerinței
                     $$ = ASTNode::createOther(resType);
                     $$->root = "OTHER"; // Ne asigurăm că label-ul este cel cerut
                 }

                 // 4. Curățăm memoria pentru string-urile numelor (ID-urilor)
                 delete $1; 
                 delete $3;
             }
           | token_id '(' call_list ')' 
             { 
                 string retType = current->getType(*$1);
                 if(retType == "") {
                     reportError("Func '%s' undefined", *$1);
                     $$ = ASTNode::createOther("error");
                 } else {
                     // Aici poți adăuga și verificarea numărului/tipului de argumente din $3
                     $$ = ASTNode::createOther(retType);
                     $$->root = "OTHER";
                 }
                 delete $1; delete $3; // $3 este vector<string>*, trebuie șters după ce verifici
             }
           | token_id '(' ')'
             {
                 // 1. Păstrăm verificarea tipului de retur din tabela de simboluri
                string retType = current->getType(*$1);

                // 2. Verificăm dacă funcția a fost definită
                if(retType == "") { 
                    reportError("Func '%s' undefined", *$1); 
                    // Returnăm un nod de eroare pentru a permite continuarea parsării
                    $$ = ASTNode::createOther("error"); 
                }
                else {
                    // 3. Conform cerinței: "if the expression is other possible operand 
                    // (function call...), the tree has only one node labelled 'OTHER'"
                    $$ = ASTNode::createOther(retType);
                    $$->root = "OTHER"; // Etichetăm explicit rădăcina cu "OTHER"
                      }

                // 4. Eliberăm memoria pentru string-ul numelui funcției ($1)
                delete $1;
              }
              | token_id DOT token_id '(' call_list ')'
             {
                 string retType = current->getMemberType(*$1, *$3);
                 if (retType.find("error") != string::npos) {
                     reportError("Method error: %s", retType);
                     $$ = ASTNode::createOther("error");
                 } else {
                     $$ = ASTNode::createOther(retType);
                     $$->root = "OTHER";
                 }
                 delete $1; delete $3; delete $5;
             }
           | token_id DOT token_id '(' ')'
             {
                 string retType = current->getMemberType(*$1, *$3);
                 if (retType.find("error") != string::npos) {
                     reportError("Method error: %s", retType);
                     $$ = ASTNode::createOther("error");
                 } else {
                     $$ = ASTNode::createOther(retType);
                     $$->root = "OTHER";
                 }
                 delete $1; delete $3;
             }
           ;
%%