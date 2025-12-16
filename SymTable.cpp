#include "SymTable.h"
using namespace std;

void SymTable::addVar(string* type, string*name) {
    IdInfo var(type, name);
    ids[*name] = var; 
}

bool SymTable::existsId(string* var) {
    return ids.count(*var) > 0;  
}

void SymTable::addClass(string* name)
{
    classes.push_back(*name);
}

bool SymTable::existsClass(string* name)
{
    for(auto s : classes)
    {
        if(s == *name)
        {
            return true;
        }
    }
    return false;
}

string SymTable::getType(string* name)
{
    if(ids.count(*name))
        return ids[*name].type;
    return "";
}

void SymTable::printVars() {
    for (const pair<string, IdInfo>& v : ids) {
        cout << "name: " << v.first << " type:" << v.second.type << endl; 
     }
}

SymTable::~SymTable() {
    ids.clear();
}











