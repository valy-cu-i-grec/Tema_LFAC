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

    if (!left && !right)
    {
        if (root == "OTHER")
        {
            if (type == "int")
                return Value(0);
            if (type == "float")
                return Value(0.0f);
            if (type == "string")
                return Value("OTHER_STR"); 
            if (type == "bool")
                return Value(false);
            return Value();
        }

        if (val.type == "id_marker")
        {
            return table->getValue(root);
        }

        return val;
    }

    if (root == ":=")
    {
        Value rightVal = right->eval(table);

        table->setValue(left->root, rightVal);
        return rightVal;
    }

    if (root == "PRINT")
    {
        Value result = left->eval(table);
        result.print(); 
        std::cout << "\n";
        return result;
    }

    Value lVal = (left) ? left->eval(table) : Value();
    Value rVal = (right) ? right->eval(table) : Value();

    if (root == "+" || root == "-" || root == "*" || root == "/")
    {
        if (lVal.type == "int")
        {
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

    if (root == "&&")
        return Value(lVal.data.bVal && rVal.data.bVal);
    if (root == "||")
        return Value(lVal.data.bVal || rVal.data.bVal);
    return Value();
}

#endif