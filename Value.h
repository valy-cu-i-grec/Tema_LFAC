#ifndef VALUE_H
#define VALUE_H

#include <string>
#include <iostream>

class Value
{
public:
    std::string type;
    bool isUnknown = false;

    union
    {
        int iVal;
        float fVal;
        bool bVal;
        char cVal;
    } data;

    std::string sVal;


    Value(const Value &other)
    {
        this->type = other.type;
        this->isUnknown = other.isUnknown;
        this->sVal = other.sVal;
        this->data = other.data;
    }

    Value &operator=(const Value &other)
    {
        if (this != &other)
        {
            this->type = other.type;
            this->isUnknown = other.isUnknown;
            this->sVal = other.sVal;
            this->data = other.data;
        }
        return *this;
    }


    Value() : type("void"), isUnknown(false) {}
    Value(std::string t, bool unknown) : type(t), isUnknown(unknown) {}
    Value(int v) : type("int"), isUnknown(false) { data.iVal = v; }
    Value(float v) : type("float"), isUnknown(false) { data.fVal = v; }
    Value(bool v) : type("bool"), isUnknown(false) { data.bVal = v; }
    Value(std::string v) : type("string"), sVal(v), isUnknown(false) {}
    Value(const char* v) : type("string"), sVal(v), isUnknown(false) {}
    Value(char v) : type("char"), isUnknown(false){ data.cVal = v; }

    void print() const
    {
        if (type == "int")
            std::cout << data.iVal;
        else if (type == "float")
            std::cout << data.fVal;
        else if (type == "bool")
            std::cout << (data.bVal ? "true" : "false");
        else if (type == "string")
            std::cout << sVal;
        else if(type == "char")
            std::cout<<data.cVal;
        else if(type == "void")
            std::cout<<"[Not evaluable]";
    }
};

#endif