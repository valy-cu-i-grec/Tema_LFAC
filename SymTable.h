#ifndef SYMTABLE_H
#define SYMTABLE_H

#include <iostream>
#include <map>
#include <string>
#include <vector>
#include <fstream>
#include "Value.h"

using namespace std;

enum IdKind
{
    VARIABLE,
    FUNCTION,
    CLASS_NAME
};

class IdInfo
{
public:
    string type;
    string name;
    IdKind kind;
    string value;
    vector<string> paramTypes;
    Value currentVal; 

    IdInfo() {}
    IdInfo(string type, string name, IdKind kind, string value = "")
        : type(type), name(name), kind(kind), value(value) {}
};

class SymTable
{
private:
    SymTable *parent;
    string scopeName;
    map<string, IdInfo> ids;
    string expectedReturnType;
    static map<string, SymTable *> classScopes;

public:
    SymTable(string name, SymTable *parent = NULL);

    bool existsId(string name);
    bool addVar(string type, string name);
    void addFunc(string type, string name);

    void updateFuncParams(string name, vector<string> params);
    vector<string> getFuncParams(string name);

    void addClass(string name);
    static void addClassScope(string name, SymTable *table);
    static SymTable *getClassScope(string name);

    string getType(string name);
    SymTable *getParent();
    string getScopeName();

    string getMemberType(string objName, string memberName);

    static bool isNumeric(string type);
    static bool isInt(string type);
    static bool isFloat(string type);
    static bool checkTypeCompatibility(string type1, string type2, string op);

    void printTableToFile(const string &filename);

    void setValue(string name, Value v);
    Value getValue(string name);

    IdKind getKind(string name); 

    void setExpectedReturnType(std::string type) { expectedReturnType = type; }
    string getExpectedReturnType();
    
    ~SymTable();
};

#endif