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
    string value;//For variables
    IdKind kind;
    vector<string> paramTypes;//For functions
   
    IdInfo() {}
    //Constructor for Variables
    IdInfo(string type, string name, string value = "") 
        : type(type), name(name), value(value), kind(VARIABLE) {}
    //Constructor for Functions
    IdInfo(string type, string name, IdKind kind) 
        : type(type), name(name), value(""), kind(kind) {}
};

class SymTable {
private:
    SymTable* parent;
    string scopeName;
    map<string, IdInfo> ids;
    vector<string> classes;

public:
    SymTable(string name, SymTable* parent = NULL);
    
    bool existsId(string* s);
    void addVar(string* type, string* name, string value = "");
    void addFunc(string* type, string* name);
    void addClass(string* name);
    bool existsClass(string* name);
    
    //Helpers
    string getType(string* name);
    SymTable* getParent();
    string getScopeName();

    //Printing
    void printTableToFile(const string& filename);
    
    ~SymTable();
};