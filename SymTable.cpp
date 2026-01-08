#include "SymTable.h"

map<string, SymTable *> SymTable::classScopes;

SymTable::SymTable(string name, SymTable *parent) : scopeName(name), parent(parent)
{
    expectedReturnType = "";
}
bool SymTable::addVar(string type, string name)
{
    if (ids.count(name))
        return false;

    if (parent != nullptr && parent->getScopeName().find("class_") == 0)
    {
        if (parent->existsId(name))
        {
            return false;
        }
    }

    IdInfo var(type, name, VARIABLE);
    ids[name] = var;
    return true;
}

void SymTable::addFunc(string type, string name)
{
    IdInfo func(type, name, FUNCTION);
    ids[name] = func;
}

bool SymTable::existsId(string name)
{
    if (ids.count(name) > 0)
        return true;
    if (parent != NULL)
        return parent->existsId(name);
    return false;
}

void SymTable::updateFuncParams(string name, vector<string> params)
{
    if (ids.count(name) && ids[name].kind == FUNCTION)
    {
        ids[name].paramTypes = params;
    }
    else if (parent != NULL)
    {
        parent->updateFuncParams(name, params);
    }
}

vector<string> SymTable::getFuncParams(string name)
{
    if (ids.count(name) && ids[name].kind == FUNCTION)
    {
        return ids[name].paramTypes;
    }
    else if (parent != NULL)
    {
        return parent->getFuncParams(name);
    }
    return vector<string>();
}

void SymTable::addClass(string name)
{
    IdInfo cls("class", name, CLASS_NAME);
    ids[name] = cls;
}

void SymTable::addClassScope(string name, SymTable *table)
{
    classScopes[name] = table;
}

SymTable *SymTable::getClassScope(string name)
{
    if (classScopes.find(name) != classScopes.end())
    {
        return classScopes[name];
    }
    return NULL;
}

string SymTable::getType(string name)
{
    if (ids.count(name))
        return ids[name].type;
    if (parent != NULL)
        return parent->getType(name);
    return "";
}

string SymTable::getMemberType(string objName, string memberName)
{
    string objType = getType(objName);
    if (objType == "")
        return "error_undef";

    SymTable *clsTable = getClassScope(objType);
    if (!clsTable)
        return "error_not_class";

    if (clsTable->ids.count(memberName))
    {
        return clsTable->ids[memberName].type;
    }
    return "error_member_missing";
}

bool SymTable::isNumeric(string type)
{
    return type == "int" || type == "float";
}
bool SymTable::isInt(string type)
{
    return type == "int";
}
bool SymTable::isFloat(string type)
{
    return type == "float";
}
bool SymTable::checkTypeCompatibility(string type1, string type2, string op)
{
    if (type1 == type2)
        return true;

    if (type1 == "error" || type2 == "error")
        return false;

    if (op == "+" || op == "-" || op == "*" || op == "/")
    {
        return (type1 == type2) && (isInt(type1) || isFloat(type1));
    }
    if (op == "&&" || op == "||")
    {
        return type1 == "bool" && type2 == "bool";
    }
    if (op == "==" || op == "!=")
    {
        return type1 == type2;
    }
    if (op == "<" || op == ">" || op == "<=" || op == ">=")
    {
        return (type1 == type2) && (isInt(type1) || isFloat(type1));
    }
    return false;
}

SymTable *SymTable::getParent() { return parent; }
string SymTable::getScopeName() { return scopeName; }

void SymTable::printTableToFile(const string &filename)
{
    ofstream file;
    file.open(filename, std::ios_base::app);
    if (file.is_open())
    {
        file << "=== Symbol Table: " << scopeName << " ===" << endl;
        file << "Parent Scope: " << (parent ? parent->getScopeName() : "NULL") << endl;
        file << "-----------------------------------" << endl;
        for (const auto &pair : ids)
        {
            IdInfo info = pair.second;
            file << "Name: " << info.name;
            if (info.kind == VARIABLE)
                file << " | Kind: Variable | Type: " << info.type;
            else if (info.kind == FUNCTION)
            {
                file << " | Kind: Function | RetType: " << info.type << " | Params: (";
                for (size_t i = 0; i < info.paramTypes.size(); ++i)
                    file << info.paramTypes[i] << (i < info.paramTypes.size() - 1 ? "," : "");
                file << ")";
            }
            else if (info.kind == CLASS_NAME)
                file << " | Kind: Class";
            file << endl;
        }
        file << "===================================\n"
             << endl;
        file.close();
    }
}

void SymTable::setValue(string name, Value v)
{
    if (ids.count(name))
    {
        ids[name].currentVal = v;
    }
    else if (parent != NULL)
    {
        parent->setValue(name, v);
    }
}

Value SymTable::getValue(string name)
{
    if (ids.count(name))
    {
        return ids[name].currentVal;
    }
    else if (parent != NULL)
    {
        return parent->getValue(name);
    }
    return Value();
}

IdKind SymTable::getKind(string name)
{
    if (ids.count(name))
        return ids[name].kind;
    if (parent)
        return parent->getKind(name);
    return VARIABLE;
}

string SymTable::getExpectedReturnType()
{
    if (expectedReturnType != "")
        return expectedReturnType;
    if (parent != NULL)
        return parent->getExpectedReturnType();
    return "";
}

SymTable::~SymTable() { ids.clear(); }