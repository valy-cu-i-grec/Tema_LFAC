#ifndef ASTNODE_H
#define ASTNODE_H

#include <vector>
#include <string>
#include "SymTable.h"

class ASTNode
{
public:
    ASTNode *left;
    ASTNode *right;
    std::string root;
    std::string type;
    Value val;

    ASTNode(Value v, std::string label)
        : left(nullptr), right(nullptr), root(label), type(v.type), val(v) {}

    ASTNode(std::string name, std::string varType)
        : left(nullptr), right(nullptr), root(name), type(varType)
    {
        // Folosim Value.type ca un marker intern:
        // Dacă val.type este "void", înseamnă că e variabilă și trebuie căutată în tabelă.
        this->val.type = "id_marker";
    }

    ASTNode(std::string op, std::string resType, ASTNode *l, ASTNode *r)
        : left(l), right(r), root(op), type(resType) {}

    ASTNode(std::string op, std::string resType, ASTNode *l)
        : left(l), right(nullptr), root(op), type(resType) {}

    static ASTNode *createOther(std::string typeName)
    {
        ASTNode *node = new ASTNode(nullptr, nullptr);
        node->root = "OTHER";
        node->type = typeName;
        return node;
    }

    Value eval(SymTable *table);

    ~ASTNode()
    {
        delete left;
        delete right;
    }

private:
    ASTNode(ASTNode *l, ASTNode *r) : left(l), right(r) {}
};

inline Value ASTNode::eval(SymTable *table)
{
    if (table == nullptr)
        return Value();

    // noduri frunza
    if (!left && !right)
    {
        // 1. Dacă este un nod "OTHER" (apel funcție/membru clasă)
        if (root == "OTHER")
        {
            if (type == "int")
                return Value(0);
            if (type == "float")
                return Value(0.0f);
            if (type == "string")
                return Value("OTHER_STR"); // Să returneze un string
            if (type == "bool")
                return Value(false);
            return Value();
        }

        // 2. Dacă este o variabilă (verificăm markerul pus în constructor)
        if (val.type == "id_marker")
        {
            return table->getValue(root);
        }

        // 3. Dacă este o constantă literală (NR, NR_FLOAT, STRING)
        // În constructorul de constante, val.type va fi "int", "float" etc., NU "id_marker"
        return val;
    }

    // atribuire id:= expr
    if (root == ":=")
    {
        Value rightVal = right->eval(table);

        table->setValue(left->root, rightVal);
        return rightVal;
    }

    // Print
    if (root == "PRINT")
    {
        Value result = left->eval(table);
        result.print(); // Aceasta va apela automat codul tău din Value.h
        std::cout << "\n";
        return result;
    }

    // Operatori
    Value lVal = (left) ? left->eval(table) : Value();
    Value rVal = (right) ? right->eval(table) : Value();

    if (root == "+" || root == "-" || root == "*" || root == "/")
    {
        if (lVal.type == "int")
        {
            // Caz de calcul întreg
            if (root == "+")
                return Value(lVal.data.iVal + rVal.data.iVal);
            if (root == "-")
                return Value(lVal.data.iVal - rVal.data.iVal);
            if (root == "*")
                return Value(lVal.data.iVal * rVal.data.iVal);
            if (root == "/")
                return (rVal.data.iVal != 0) ? Value(lVal.data.iVal / rVal.data.iVal) : Value(0);
        }
        else if (lVal.type == "float")
        {
            // Caz de calcul float
            if (root == "+")
                return Value(lVal.data.fVal + rVal.data.fVal);
            if (root == "-")
                return Value(lVal.data.fVal - rVal.data.fVal);
            if (root == "*")
                return Value(lVal.data.fVal * rVal.data.fVal);
            if (root == "/")
                return (rVal.data.fVal != 0.0f) ? Value(lVal.data.fVal / rVal.data.fVal) : Value(0.0f);
        }
    }

    // operatorul unar !
    lVal = (left) ? left->eval(table) : Value();

    if (root == "!")
    {
        if (lVal.isUnknown)
        {
            return Value("bool", true);
        }

        if (lVal.type == "bool")
        {
            return Value(!lVal.data.bVal);
        }

        return Value("bool", true);
    }

    // Operatori de comparație
    if (root == "==")
    {
        if (lVal.type == "int")
            return Value(lVal.data.iVal == rVal.data.iVal);
        if (lVal.type == "float")
            return Value(lVal.data.fVal == rVal.data.fVal);
        if (lVal.type == "string")
            return Value(lVal.sVal == rVal.sVal);
        if (lVal.type == "bool")
            return Value(lVal.data.bVal == rVal.data.bVal);
    }
    if (root == "!=")
    {
        if (lVal.type == "int")
            return Value(lVal.data.iVal != rVal.data.iVal);
        if (lVal.type == "float")
            return Value(lVal.data.fVal != rVal.data.fVal);
        if (lVal.type == "string")
            return Value(lVal.sVal != rVal.sVal);
        if (lVal.type == "bool")
            return Value(lVal.data.bVal != rVal.data.bVal);
    }
    if (root == "<")
    {
        if (lVal.type == "int")
            return Value(lVal.data.iVal < rVal.data.iVal);
        if (lVal.type == "float")
            return Value(lVal.data.fVal < rVal.data.fVal);
    }
    if (root == ">")
    {
        if (lVal.type == "int")
            return Value(lVal.data.iVal > rVal.data.iVal);
        if (lVal.type == "float")
            return Value(lVal.data.fVal > rVal.data.fVal);
    }

    // Operatori booleeni
    if (root == "&&")
        return Value(lVal.data.bVal && rVal.data.bVal);
    if (root == "||")
        return Value(lVal.data.bVal || rVal.data.bVal);
    return Value();
}

#endif