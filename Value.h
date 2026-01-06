#ifndef VALUE_H
#define VALUE_H

#include <string>
#include <iostream>

class Value {
public:
    std::string type; // "int", "float", "bool", "string", "void"
    
    union {
        int iVal;
        float fVal;
        bool bVal;
    } data;
    
    std::string sVal;

    // Constructori
    Value() : type("void") {}
    Value(std::string t) : type(t) {} // Constructorul cerut de profă: Value("int") ### NU INTELEG CE E ASTA TBH:)))
    Value(int v) : type("int") { data.iVal = v; }
    Value(float v) : type("float") { data.fVal = v; }
    Value(bool v) : type("bool") { data.bVal = v; }
    Value(std::string v) : type("string"), sVal(v) {}

    void print() const {
        if (type == "int") std::cout << data.iVal;
        else if (type == "float") std::cout << data.fVal;
        else if (type == "bool") std::cout << (data.bVal ? "true" : "false");
        else if (type == "string") std::cout << sVal;
    }
};

#endif