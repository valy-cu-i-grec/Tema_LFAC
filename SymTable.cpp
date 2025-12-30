#include "SymTable.h"
#include <fstream>

using namespace std;

SymTable::SymTable(string name, SymTable* parent) : scopeName(name), parent(parent) {}

void SymTable::addVar(string* type, string* name, string value) {
    IdInfo var(*type, *name, value);
    ids[*name] = var; 
}

void SymTable::addFunc(string* type, string* name) {
    IdInfo func(*type, *name, FUNCTION);
    ids[*name] = func;
}

bool SymTable::existsId(string* var) {
    //verific scope curent
    if (ids.count(*var) > 0) return true;
    
    //verific scope parinte recursiv
    if (parent != NULL) {
        return parent->existsId(var);
    }
    return false;
}

void SymTable::addClass(string* name) {
    classes.push_back(*name);
}

bool SymTable::existsClass(string* name) {
    for(auto s : classes) {
        if(s == *name) return true;
    }
    if (parent != NULL) {
        return parent->existsClass(name);
    }
    return false;
}

string SymTable::getType(string* name) {
    if(ids.count(*name))
        return ids[*name].type;
    
    if(parent != NULL)
        return parent->getType(name);
        
    return "";
}

SymTable* SymTable::getParent() {
    return parent;
}

string SymTable::getScopeName() {
    return scopeName;
}

void SymTable::printTableToFile(const string& filename) {
    ofstream file;
    file.open(filename, std::ios_base::app); //Append mode

    if (file.is_open()) {
        file << "Symbol Table: " << scopeName << '\n';
        if (parent) {
            file << "Parent Scope: " << parent->getScopeName() << '\n';
        } else {
            file << "Parent Scope: NULL" << '\n';
        }

        for (const auto& pair : ids) {
            IdInfo info = pair.second;
            file << "Name: " << info.name;
            
            if (info.kind == VARIABLE) {
                file << " | Kind: Variable | Type: " << info.type;
                if (!info.value.empty()) file << " | Value: " << info.value;
            } else if (info.kind == FUNCTION) {
                file << " | Kind: Function | RetType: " << info.type;
            } else if (info.kind == CLASS_NAME) {
                 file << " | Kind: Class";
            }
            file << endl;
        }
        file << "\n";
        file.close();
    } else {
        cerr << "Unable to open file " << filename << endl;
    }
}

SymTable::~SymTable() {
    ids.clear();
}