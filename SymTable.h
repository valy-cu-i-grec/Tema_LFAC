#include <iostream>
#include <map>
#include <string>
#include <vector>
using namespace std;

class IdInfo {
    public:
    string type;
    string name;
   
    IdInfo() {}
    IdInfo(string* type, string* name) : type(*type), name(*name) {}
};

class SymTable {
private:
    SymTable* parent;
    map<string, IdInfo> ids;
    vector<string> classes;
    string name;

public:
    SymTable(const char* , SymTable* parent = NULL) :  name(name){}
    bool existsId(string* s);
    void addVar(string* type, string* name );
    void addFunc(string* type, string* name );
    void addClass(string* name);
    bool existsClass(string* name);
    void printVars();
    string getType(string* name);
    //void printFunc();
    ~SymTable();
};






