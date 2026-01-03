#include <iostream>
#include <map>
#include <string>
#include <vector>
#include <fstream>

using namespace std;

enum IdKind { VARIABLE, FUNCTION, CLASS_NAME };

class IdInfo {
    public:
    string type;
    string name;
    IdKind kind;
    string value;
    vector<string> paramTypes; 

    IdInfo() {}
    IdInfo(string type, string name, IdKind kind, string value = "") 
        : type(type), name(name), kind(kind), value(value) {}
};

class SymTable {
private:
    SymTable* parent;
    string scopeName;
    map<string, IdInfo> ids;
    
    // Static map pentru a stoca toate scope-urile claselor (Global storage, dar incapsulat)
    static map<string, SymTable*> classScopes;

public:
    SymTable(string name, SymTable* parent = NULL);
    
    // Core methods
    bool existsId(string name);
    // Returneaza false si seteaza mesajul de eroare daca ceva nu e ok
    bool addVar(string type, string name);
    void addFunc(string type, string name);
    
    // Gestionare Parametri
    void updateFuncParams(string name, vector<string> params);
    vector<string> getFuncParams(string name);

    // Gestionare Clase
    void addClass(string name);
    static void addClassScope(string name, SymTable* table);
    static SymTable* getClassScope(string name);
    
    // Helpers & Type Checking
    string getType(string name);
    SymTable* getParent();
    string getScopeName();
    
    // Verifica daca membrul exista in clasa si returneaza tipul
    string getMemberType(string objName, string memberName);
    
    // Functii de verificare statice (pentru a nu incarca .y)
    static bool isNumeric(string type);
    static bool checkTypeCompatibility(string type1, string type2, string op);

    // Printing
    void printTableToFile(const string& filename);
    
    ~SymTable();
};