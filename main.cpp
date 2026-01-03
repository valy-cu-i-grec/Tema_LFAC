#include <iostream>
#include <fstream>
#include "SymTable.h"

// Variabile externe necesare pentru Flex/Bison
extern FILE* yyin;
extern int yylineno;
extern int yyparse();

// Global Pointer - singura variabila globala de logica necesara
SymTable* current;

void yyerror(const char * s);

int main(int argc, char** argv){
    // Golim fisierul de output
    std::ofstream file("tables.txt");
    file.close();

    if(argc > 1) yyin=fopen(argv[1],"r");
    else yyin = stdin;
     
    current = new SymTable("global");
    
    yyparse();
     
    // Printam tabela globala la final (daca nu a crapat totul)
    if(current) {
        current->printTableToFile("tables.txt");
        delete current;
    }
    return 0;
}

void yyerror(const char * s){
     std::cout << "Error: " << s << " at line: " << yylineno << std::endl;
}