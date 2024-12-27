%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void yyerror(const char *s);
int yylex(void);

extern int line_num;
extern int char_num;

typedef struct Symbol {
    char *name;
    int defined;
    struct Symbol *next;
} Symbol;

Symbol *symbol_table = NULL;

void add_symbol(char *name) {
    Symbol *sym = (Symbol *)malloc(sizeof(Symbol));
    sym->name = strdup(name);
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
}

%token <stringValue> IDENTIFIER
%token <intValue> INTEGER
%token <floatValue> FLOAT
%token KEYWORD COLLECTION CONSTANT_DECLARATION VARIABLE_DECLARATION ARRAY_IDENTIFIER LOOP_TILL LOOP_FOR BREAK CONTINUE FUNCTION RETURN IF ELIF ELSE CASE BLOCK_COMMENT LINE_COMMENT CONDITIONAL_OPERATOR LOGICAL_OPERATOR BITWISE_OPERATOR ARITHMETIC_OPERATOR RANGE_OPERATOR SEMICOLON SEPARATOR STRING_LITERAL NUMBER MEMBER_ACCESS

%left '+' '-'
%left '*' '/'
%left '&' '|' '~' '^^'
%left "==" "<" ">" "<=" ">="
%left "&&" "||" "!"

%%

program:
    program statement '\n'
    | /* NULL */
    ;

statement:
    declaration
    | assignment
    | loop
    | function
    | condition
    | expression
    ;

declaration:
    CONSTANT_DECLARATION { printf("Constant Declaration: %s\n", $1); }
    | VARIABLE_DECLARATION { printf("Variable Declaration: %s\n", $1); }
    | ARRAY_IDENTIFIER { printf("Array Identifier: %s\n", $1); }
    ;

assignment:
    IDENTIFIER '=' expression { 
        Symbol *sym = find_symbol($1);
        if (!sym) {
            yyerror("Undeclared identifier");
        } else {
            printf("Assignment: %s = %d\n", $1, $3); 
        }
    }
    ;

loop:
    LOOP_TILL { printf("Loop Till\n"); }
    | LOOP_FOR { printf("Loop For\n"); }
    | BREAK { printf("Break\n"); }
    | CONTINUE { printf("Continue\n"); }
    ;

function:
    FUNCTION { 
        if (find_symbol($1)) {
            yyerror("Duplicate function definition");
        } else {
            add_symbol($1);
            define_symbol($1);
            printf("Function: %s\n", $1); 
        }
    }
    | RETURN { printf("Return\n"); }
    ;

condition:
    IF { printf("If\n"); }
    | ELIF { printf("Elif\n"); }
    | ELSE { printf("Else\n"); }
    | CASE { printf("Case\n"); }
    ;

expression:
    INTEGER { $$ = $1; }
    | FLOAT { $$ = $1; }
    | IDENTIFIER { 
        Symbol *sym = find_symbol($1);
        if (!sym) {
            yyerror("Undeclared identifier");
        } else {
            $$ = $1; 
        }
    }
    | expression ARITHMETIC_OPERATOR expression { $$ = $1 + $3; }
    | expression BITWISE_OPERATOR expression { $$ = $1 & $3; }
    | expression CONDITIONAL_OPERATOR expression { $$ = $1 == $3; }
    | expression LOGICAL_OPERATOR expression { $$ = $1 && $3; }
    | '(' expression ')' { $$ = $2; }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s at line %d, character %d\n", s, line_num, char_num);
}

int main(void) {
    if (yyparse() == 0 && !check_main_defined()) {
        fprintf(stderr, "Error: main function not defined\n");
        return 1;
    }
    return 0;
}
