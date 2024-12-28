%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void yyerror(const char *s);
int yylex(void);

extern int line_num;
extern int char_num;
extern char *yytext;

typedef struct Symbol {
    char *name;
    char *data_type;
    int defined;
    struct Symbol *next;
} Symbol;

Symbol *symbol_table = NULL;

void add_symbol(char *name, char *data_type) {
    Symbol *sym = (Symbol *)malloc(sizeof(Symbol));
    sym->name = strdup(name);
    sym->data_type = strdup(data_type);
    sym->defined = 0;
    sym->next = symbol_table;
    symbol_table = sym;
}

Symbol *find_symbol(char *name) {
    Symbol *sym = symbol_table;
    while (sym) {
        if (strcmp(sym->name, name) == 0) {
            return sym;
        }
        sym = sym->next;
    }
    return NULL;
}

void define_symbol(char *name) {
    Symbol *sym = find_symbol(name);
    if (sym) {
        sym->defined = 1;
    }
}

int check_main_defined() {
    Symbol *sym = find_symbol("main");
    return sym && sym->defined;
}

%}

%union {
    int intValue;
    float floatValue;
    char *stringValue;
    struct {
        char *name;
        char *type;
    } declaration;
    struct {
        char *name;
        char *returnType;
    } function;
}

%token <stringValue> IDENTIFIER
%token <intValue> INTEGER
%token <floatValue> FLOAT
%token <stringValue> CONSTANT_DECLARATION VARIABLE_DECLARATION ARRAY_IDENTIFIER
%token <stringValue> FUNCTION
%token LOOP_TILL LOOP_FOR BREAK CONTINUE RETURN IF ELIF ELSE CASE 
%token BLOCK_COMMENT LINE_COMMENT SEMICOLON SEPARATOR STRING_LITERAL NUMBER MEMBER_ACCESS KEYWORD COLLECTION

%token <stringValue> ARITHMETIC_OP_PLUS ARITHMETIC_OP_MINUS ARITHMETIC_OP_MULT ARITHMETIC_OP_DIV
%token <stringValue> BITWISE_OP_AND BITWISE_OP_OR BITWISE_OP_NOT BITWISE_OP_XOR
%token <stringValue> CONDITIONAL_OP_EQ CONDITIONAL_OP_LT CONDITIONAL_OP_GT CONDITIONAL_OP_LE CONDITIONAL_OP_GE
%token <stringValue> LOGICAL_OP_AND LOGICAL_OP_OR LOGICAL_OP_NOT

%type <declaration> declaration
%type <stringValue> expression expr_arithmetic expr_bitwise expr_conditional expr_logical
%type <stringValue> primary_expression
%type <function> function_statement
%type <stringValue> assignment statements statement loop_statement condition_statement
%type <stringValue> else_if_list else_block block program

%left LOGICAL_OP_OR
%left LOGICAL_OP_AND
%left BITWISE_OP_OR
%left BITWISE_OP_XOR
%left BITWISE_OP_AND
%left CONDITIONAL_OP_EQ
%left CONDITIONAL_OP_LT CONDITIONAL_OP_GT CONDITIONAL_OP_LE CONDITIONAL_OP_GE
%left ARITHMETIC_OP_PLUS ARITHMETIC_OP_MINUS
%left ARITHMETIC_OP_MULT ARITHMETIC_OP_DIV
%right LOGICAL_OP_NOT BITWISE_OP_NOT

%%

program:
    statements { $$ = $1; }
    ;

statements:
    statements statement '\n' { $$ = $1; }
    | /* empty */ { $$ = strdup(""); }
    ;

statement:
    declaration SEMICOLON { $$ = strdup(""); }
    | assignment SEMICOLON { $$ = $1; }
    | loop_statement { $$ = $1; }
    | function_statement { $$ = strdup(""); }
    | condition_statement { $$ = $1; }
    | expression SEMICOLON { $$ = $1; }
    | BLOCK_COMMENT { $$ = strdup(""); }
    | LINE_COMMENT { $$ = strdup(""); }
    ;

declaration:
    CONSTANT_DECLARATION ':' expression { 
        $$.name = $1; 
        $$.type = "constant"; 
        printf("Constant Declaration: %s = %s\n", $1, $3); 
        add_symbol($1, "constant");
    }
    | VARIABLE_DECLARATION { 
        $$.name = $1; 
        $$.type = "variable"; 
        printf("Variable Declaration: %s\n", $1); 
        add_symbol($1, "variable");
    }
    | VARIABLE_DECLARATION ':' expression { 
        $$.name = $1; 
        $$.type = "variable"; 
        printf("Variable Declaration with Initialization: %s = %s\n", $1, $3); 
        add_symbol($1, "variable");
    }
    | ARRAY_IDENTIFIER { 
        $$.name = $1; 
        $$.type = "array"; 
        printf("Array Identifier: %s\n", $1); 
        add_symbol($1, "array");
    }
    ;

assignment:
    IDENTIFIER ':' expression { 
        Symbol *sym = find_symbol($1);
        if (!sym) {
            yyerror("Undeclared identifier");
            $$ = strdup("");
        } else {
            if ((strcmp(sym->data_type, "int") == 0 || strcmp(sym->data_type, "float") == 0) && 
                (strcmp($3, "int") == 0 || strcmp($3, "float") == 0)) {
                $$ = strdup($1);
                printf("Assignment: %s = %s\n", $1, $3); 
            } else if (strcmp(sym->data_type, $3) != 0) {
                yyerror("Type mismatch in assignment");
                $$ = strdup("");
            } else {
                $$ = strdup($1);
                printf("Assignment: %s = %s\n", $1, $3); 
            }
        }
    }
    ;

loop_statement:
    LOOP_TILL statement { $$ = strdup("loop_till"); }
    | LOOP_FOR statement { $$ = strdup("loop_for"); }
    | BREAK SEMICOLON { $$ = strdup("break"); }
    | CONTINUE SEMICOLON { $$ = strdup("continue"); }
    ;

function_statement:
    FUNCTION block { 
        if (find_symbol($1)) {
            yyerror("Duplicate function definition");
            $$.name = "";
            $$.returnType = "";
        } else {
            add_symbol($1, "function");
            define_symbol($1);
            $$.name = $1;
            $$.returnType = "void";
            printf("Function: %s\n", $1); 
        }
    }
    | RETURN expression SEMICOLON { 
        printf("Return\n");
        $$.name = "return";
        $$.returnType = "void";
    }
    ;

condition_statement:
    IF expression block else_if_list else_block { $$ = strdup("if"); }
    ;

else_if_list:
    else_if_list ELIF expression block { $$ = strdup("elif"); }
    | /* empty */ { $$ = strdup(""); }
    ;

else_block:
    ELSE block { $$ = strdup("else"); }
    | /* empty */ { $$ = strdup(""); }
    ;

block:
    '{' statements '}' { $$ = $2; }
    ;

expression:
    expr_arithmetic { $$ = $1; }
    | expr_bitwise { $$ = $1; }
    | expr_conditional { $$ = $1; }
    | expr_logical { $$ = $1; }
    | primary_expression { $$ = $1; }
    ;

primary_expression:
    INTEGER { 
        char buf[32]; 
        sprintf(buf, "%d", $1); 
        $$ = strdup(buf); 
    }
    | FLOAT { 
        char buf[32]; 
        sprintf(buf, "%f", $1); 
        $$ = strdup(buf); 
    }
    | IDENTIFIER { 
        Symbol *sym = find_symbol($1);
        if (!sym) {
            yyerror("Undeclared identifier");
            $$ = strdup("");
        } else {
            $$ = strdup($1);
        }
    }
    | '(' expression ')' { $$ = $2; }
    ;

expr_arithmetic:
    expression ARITHMETIC_OP_PLUS expression { $$ = strdup($1); }
    | expression ARITHMETIC_OP_MINUS expression { $$ = strdup($1); }
    | expression ARITHMETIC_OP_MULT expression { $$ = strdup($1); }
    | expression ARITHMETIC_OP_DIV expression { $$ = strdup($1); }
    ;

expr_bitwise:
    expression BITWISE_OP_AND expression { $$ = strdup($1); }
    | expression BITWISE_OP_OR expression { $$ = strdup($1); }
    | expression BITWISE_OP_XOR expression { $$ = strdup($1); }
    | BITWISE_OP_NOT expression { $$ = strdup($2); }
    ;

expr_conditional:
    expression CONDITIONAL_OP_EQ expression { $$ = strdup($1); }
    | expression CONDITIONAL_OP_LT expression { $$ = strdup($1); }
    | expression CONDITIONAL_OP_GT expression { $$ = strdup($1); }
    | expression CONDITIONAL_OP_LE expression { $$ = strdup($1); }
    | expression CONDITIONAL_OP_GE expression { $$ = strdup($1); }
    ;

expr_logical:
    expression LOGICAL_OP_AND expression { $$ = strdup($1); }
    | expression LOGICAL_OP_OR expression { $$ = strdup($1); }
    | LOGICAL_OP_NOT expression { $$ = strdup($2); }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s at line %d, character %d, token: %s\n", s, line_num, char_num, yytext);
}

int main(void) {
    if (yyparse() == 0 && !check_main_defined()) {
        fprintf(stderr, "Error: main function not defined\n");
        return 1;
    }
    return 0;
}