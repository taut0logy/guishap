%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// External declarations for lexer variables
extern int line_number;
extern char *yytext;
extern int yylineno;
extern FILE *yyin;

// Function declarations
int yylex(void);
void yyerror(const char *s);

// Symbol table structure
typedef struct Symbol {
    char *name;
    char *type;
    int is_const;
    int is_array;
    int scope_level;
    struct Symbol *next;
} Symbol;

// Function table structure
typedef struct Function {
    char *name;
    char *return_type;
    Symbol *params;
    int scope_level;
    struct Function *next;
} Function;

// Collection table structure
typedef struct Collection {
    char *name;
    Symbol *members;
    int scope_level;
    struct Collection *next;
} Collection;

// Global symbol tables
Symbol *symbol_table = NULL;
Function *function_table = NULL;
Collection *collection_table = NULL;

// Current scope tracking
extern int scope_level;
extern char current_function[256];

// Statistics
int declarations = 0;
int assignments = 0;
int function_calls = 0;
int conditions = 0;
int loops = 0;

// Helper functions
void enter_scope(void);
void exit_scope(void);
void add_symbol(const char *name, const char *type, int is_const, int is_array);
void add_function(const char *name, const char *return_type);
void add_collection(const char *name);
Symbol *find_symbol(const char *name);
Function *find_function(const char *name);
Collection *find_collection(const char *name);
void print_scope_info(const char *action, const char *details);

// Operation logging functions
void log_declaration(const char *kind, const char *name, const char *type, const char *value);
void log_assignment(const char *target, const char *value, const char *type);
void log_operation(const char *op, const char *left, const char *right, const char *result);
void log_function_call(const char *name, int arg_count);
void log_condition(const char *type, const char *condition);
void log_loop(const char *type, const char *condition);
void log_collection_access(const char *collection, const char *member);
void log_array_access(const char *array, const char *index);

%}

%union {
    int ival;
    float fval;
    char *sval;
    struct {
        char *name;
        char *type;
    } decl;
}

/* Tokens */
%token <sval> IDENTIFIER STRING
%token <ival> INTEGER
%token <fval> FLOAT

/* Keywords */
%token COL SHAP RET
%token LOOP_TILL LOOP FOR
%token BREAK CONTINUE
%token IF ELIF ELSE CASE
%token TYPE_VOID TYPE_INT TYPE_FLOAT TYPE_STRING TYPE_BOOL

/* Declarations */
%token <sval> VAR_DECL CONST_DECL ARRAY_DECL

/* Operators */
%token ASSIGN RANGE
%token EQ LT GT LE GE
%token AND OR NOT

/* Types */
%type <sval> type expression statement
%type <decl> declaration
%type <sval> member_list member parameter_list parameter
%type <sval> block case_list case_item argument_list

/* Operator precedence */
%left OR
%left AND
%left '|'
%left '^'
%left '&'
%left EQ
%left LT GT LE GE
%left '+' '-'
%left '*' '/' '%'
%right NOT '~'
%right UMINUS

%%

program
    : statement_list
    ;

statement_list
    : statement
    | statement_list statement
    ;

statement
    : declaration ';'                  { $$ = $1.name; }
    | collection_definition           { $$ = "collection"; }
    | function_definition            { $$ = "function"; }
    | assignment ';'                 { $$ = "assignment"; }
    | expression ';'                 { $$ = $1; }
    | if_statement                   { $$ = "if"; conditions++; }
    | loop_statement                 { $$ = "loop"; }
    | case_statement                 { $$ = "case"; }
    | BREAK ';'                      { print_scope_info("Break Statement", ""); $$ = "break"; }
    | CONTINUE ';'                   { print_scope_info("Continue Statement", ""); $$ = "continue"; }
    | RET expression ';'             { print_scope_info("Return Statement", $2); $$ = "return"; }
    | block                          { $$ = $1; }
    | ';'                           { $$ = "empty"; }
    ;

declaration
    : VAR_DECL {
        char *type = strchr($1, '%');
        if (type) {
            type++;
            $$.name = $1;
            $$.type = strdup(type);
            add_symbol($1, type, 0, 0);
            declarations++;
            log_declaration("Variable", $1, type, NULL);
        }
    }
    | CONST_DECL {
        char *type = strchr($1, '%');
        if (type) {
            type++;
            $$.name = $1;
            $$.type = strdup(type);
            add_symbol($1, type, 1, 0);
            declarations++;
            log_declaration("Constant", $1, type, NULL);
        }
    }
    | ARRAY_DECL {
        char *type = strchr($1, '%');
        if (type) {
            type++;
            $$.name = $1;
            $$.type = strdup(type);
            add_symbol($1, type, 0, 1);
            declarations++;
            log_declaration("Array", $1, type, NULL);
        }
    }
    | VAR_DECL ASSIGN expression {
        char *type = strchr($1, '%');
        if (type) {
            type++;
            $$.name = $1;
            $$.type = strdup(type);
            add_symbol($1, type, 0, 0);
            declarations++;
            assignments++;
            log_declaration("Variable", $1, type, $3);
        }
    }
    | CONST_DECL ASSIGN expression {
        char *type = strchr($1, '%');
        if (type) {
            type++;
            $$.name = $1;
            $$.type = strdup(type);
            add_symbol($1, type, 1, 0);
            declarations++;
            assignments++;
            log_declaration("Constant", $1, type, $3);
        }
    }
    | ARRAY_DECL ASSIGN expression {
        char *type = strchr($1, '%');
        if (type) {
            type++;
            $$.name = $1;
            $$.type = strdup(type);
            add_symbol($1, type, 0, 1);
            declarations++;
            assignments++;
            log_declaration("Array", $1, type, $3);
        }
    }
    ;

collection_definition
    : COL IDENTIFIER { enter_scope(); print_scope_info("Collection Start", $2); }
      '{' member_list '}' ';' {
        add_collection($2);
        print_scope_info("Collection End", $2);
        exit_scope();
    }
    ;

member_list
    : member                        { $$ = $1; }
    | member_list ',' member        { $$ = $3; }
    ;

member
    : VAR_DECL                     { 
        $$ = $1;
        char *type = strchr($1, '%');
        if (type) {
            type++;
            add_symbol($1, type, 0, 0);
            print_scope_info("Collection Member", $1);
        }
    }
    | ARRAY_DECL                   { 
        $$ = $1;
        char *type = strchr($1, '%');
        if (type) {
            type++;
            add_symbol($1, type, 0, 1);
            print_scope_info("Collection Array Member", $1);
        }
    }
    ;

function_definition
    : SHAP IDENTIFIER { 
        enter_scope(); 
        strncpy(current_function, $2, sizeof(current_function)-1);
        print_scope_info("Function Start", $2);
    }
    '(' parameter_list ')' '>' type block {
        add_function($2, $8);
        print_scope_info("Function End", $2);
        current_function[0] = '\0';
        exit_scope();
    }
    ;

parameter_list
    : /* empty */                  { $$ = ""; }
    | parameter                    { $$ = $1; }
    | parameter_list ',' parameter { $$ = $3; }
    ;

parameter
    : VAR_DECL                     { 
        $$ = $1;
        char *type = strchr($1, '%');
        if (type) {
            type++;
            add_symbol($1, type, 0, 0);
            print_scope_info("Parameter", $1);
        }
    }
    | ARRAY_DECL                   { 
        $$ = $1;
        char *type = strchr($1, '%');
        if (type) {
            type++;
            add_symbol($1, type, 0, 1);
            print_scope_info("Array Parameter", $1);
        }
    }
    | CONST_DECL ASSIGN expression { 
        $$ = $1;
        char *type = strchr($1, '%');
        if (type) {
            type++;
            add_symbol($1, type, 1, 0);
            print_scope_info("Constant Parameter", $1);
        }
    }
    ;

block
    : '{' { enter_scope(); } statement_list '}' { 
        $$ = "block";
        exit_scope();
    }
    | '{' '}' { $$ = "empty block"; }
    ;

assignment
    : IDENTIFIER ASSIGN expression {
        Symbol *sym = find_symbol($1);
        if (sym) {
            if (sym->is_const) {
                yyerror("Cannot assign to constant");
            } else {
                assignments++;
                log_assignment($1, $3, sym->type);
            }
        } else {
            char error[256];
            snprintf(error, sizeof(error), "Undefined variable '%s'", $1);
            yyerror(error);
        }
    }
    | IDENTIFIER '[' expression ']' ASSIGN expression {
        Symbol *sym = find_symbol($1);
        if (sym && sym->is_array) {
            assignments++;
            log_array_access($1, $3);
            log_assignment($1, $6, sym->type);
        } else {
            char error[256];
            snprintf(error, sizeof(error), "'%s' is not an array", $1);
            yyerror(error);
        }
    }
    | IDENTIFIER '.' IDENTIFIER ASSIGN expression {
        Collection *col = find_collection($1);
        if (col) {
            assignments++;
            log_collection_access($1, $3);
            log_assignment($3, $5, "member");
        } else {
            char error[256];
            snprintf(error, sizeof(error), "Undefined collection '%s'", $1);
            yyerror(error);
        }
    }
    ;

if_statement
    : IF '[' expression ']' { log_condition("If", $3); enter_scope(); } 
      block { exit_scope(); }
    | if_statement ELIF '[' expression ']' { log_condition("Elif", $4); enter_scope(); } 
      block { exit_scope(); }
    | if_statement ELSE { log_condition("Else", ""); enter_scope(); } 
      block { exit_scope(); }
    ;

loop_statement
    : LOOP_TILL '[' expression ']' { log_loop("Loop Till", $3); enter_scope(); } 
      block { 
        loops++;
        exit_scope();
    }
    | LOOP VAR_DECL FOR range_expression { log_loop("Loop For", $2); enter_scope(); } 
      block { 
        loops++;
        exit_scope();
    }
    ;

range_expression
    : '[' expression RANGE expression ']'
    | '[' expression RANGE expression RANGE expression ']'
    ;

case_statement
    : CASE '[' expression ']' '{' case_list '}'
    ;

case_list
    : case_item                    { $$ = $1; }
    | case_list case_item         { $$ = $2; }
    ;

case_item
    : '[' expression ']' ':' { enter_scope(); } statement { 
        $$ = "case";
        exit_scope();
    }
    | '[' ']' ':' { enter_scope(); } statement { 
        $$ = "default";
        exit_scope();
    }
    ;

expression
    : INTEGER                      { char buf[32]; sprintf(buf, "%d", $1); $$ = strdup(buf); }
    | FLOAT                       { char buf[32]; sprintf(buf, "%g", $1); $$ = strdup(buf); }
    | STRING                      { $$ = $1; }
    | IDENTIFIER                  { 
        Symbol *sym = find_symbol($1);
        if (!sym) {
            char error[256];
            snprintf(error, sizeof(error), "Undefined identifier '%s'", $1);
            yyerror(error);
        }
        $$ = $1;
    }
    | IDENTIFIER '[' expression ']' { 
        Symbol *sym = find_symbol($1);
        if (!sym || !sym->is_array) {
            char error[256];
            snprintf(error, sizeof(error), "'%s' is not an array", $1);
            yyerror(error);
        }
        log_array_access($1, $3);
        $$ = $1;
    }
    | IDENTIFIER '.' IDENTIFIER   { 
        Collection *col = find_collection($1);
        if (!col) {
            char error[256];
            snprintf(error, sizeof(error), "Undefined collection '%s'", $1);
            yyerror(error);
        }
        log_collection_access($1, $3);
        $$ = $3;
    }
    | IDENTIFIER '(' argument_list ')' { 
        Function *func = find_function($1);
        if (!func) {
            char error[256];
            snprintf(error, sizeof(error), "Undefined function '%s'", $1);
            yyerror(error);
        } else {
            function_calls++;
            log_function_call($1, 1); // TODO: Count actual arguments
        }
        $$ = $1;
    }
    | '(' expression ')'          { $$ = $2; }
    | expression '+' expression   { log_operation("Addition", $1, $3, "result"); $$ = "add"; }
    | expression '-' expression   { log_operation("Subtraction", $1, $3, "result"); $$ = "sub"; }
    | expression '*' expression   { log_operation("Multiplication", $1, $3, "result"); $$ = "mul"; }
    | expression '/' expression   { log_operation("Division", $1, $3, "result"); $$ = "div"; }
    | expression '%' expression   { log_operation("Modulo", $1, $3, "result"); $$ = "mod"; }
    | expression '&' expression   { log_operation("Bitwise AND", $1, $3, "result"); $$ = "and"; }
    | expression '|' expression   { log_operation("Bitwise OR", $1, $3, "result"); $$ = "or"; }
    | expression '^' expression   { log_operation("Bitwise XOR", $1, $3, "result"); $$ = "xor"; }
    | '~' expression             { log_operation("Bitwise NOT", $2, "", "result"); $$ = "not"; }
    | expression EQ expression    { log_operation("Equals", $1, $3, "result"); $$ = "eq"; }
    | expression LT expression    { log_operation("Less Than", $1, $3, "result"); $$ = "lt"; }
    | expression GT expression    { log_operation("Greater Than", $1, $3, "result"); $$ = "gt"; }
    | expression LE expression    { log_operation("Less Equal", $1, $3, "result"); $$ = "le"; }
    | expression GE expression    { log_operation("Greater Equal", $1, $3, "result"); $$ = "ge"; }
    | expression AND expression   { log_operation("Logical AND", $1, $3, "result"); $$ = "logical_and"; }
    | expression OR expression    { log_operation("Logical OR", $1, $3, "result"); $$ = "logical_or"; }
    | NOT expression             { log_operation("Logical NOT", $2, "", "result"); $$ = "logical_not"; }
    | '-' expression %prec UMINUS { log_operation("Negation", $2, "", "result"); $$ = "neg"; }
    ;

argument_list
    : /* empty */                  { $$ = ""; }
    | expression                   { $$ = $1; }
    | argument_list ',' expression { $$ = $3; }
    ;

type
    : TYPE_VOID                    { $$ = "void"; }
    | TYPE_INT                     { $$ = "int"; }
    | TYPE_FLOAT                   { $$ = "float"; }
    | TYPE_STRING                  { $$ = "string"; }
    | TYPE_BOOL                    { $$ = "bool"; }
    | IDENTIFIER                   { $$ = $1; }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Error at line %d: %s\n", line_number, s);
    fprintf(stderr, "Near token: '%s'\n", yytext);
}

void print_scope_info(const char *action, const char *details) {
    char indent[256] = "";
    for (int i = 0; i < scope_level; i++) {
        strcat(indent, "  ");
    }
    
    char context[512] = "";
    if (current_function[0] != '\0') {
        sprintf(context, " [in function %s]", current_function);
    }
    
    printf("Line %d%s: %s%s: %s\n", line_number, context, indent, action, details);
}

void add_symbol(const char *name, const char *type, int is_const, int is_array) {
    // Check for duplicate in current scope
    for (Symbol *sym = symbol_table; sym != NULL; sym = sym->next) {
        if (sym->scope_level == scope_level && strcmp(sym->name, name) == 0) {
            char error[256];
            snprintf(error, sizeof(error), "Duplicate identifier '%s' in current scope", name);
            yyerror(error);
            return;
        }
    }

    Symbol *sym = malloc(sizeof(Symbol));
    sym->name = strdup(name);
    sym->type = strdup(type);
    sym->is_const = is_const;
    sym->is_array = is_array;
    sym->scope_level = scope_level;
    sym->next = symbol_table;
    symbol_table = sym;
}

void add_function(const char *name, const char *return_type) {
    // Check for duplicate function
    if (find_function(name)) {
        char error[256];
        snprintf(error, sizeof(error), "Duplicate function '%s'", name);
        yyerror(error);
        return;
    }

    Function *func = malloc(sizeof(Function));
    func->name = strdup(name);
    func->return_type = strdup(return_type);
    func->params = NULL;
    func->scope_level = scope_level;
    func->next = function_table;
    function_table = func;
}

void add_collection(const char *name) {
    // Check for duplicate collection
    if (find_collection(name)) {
        char error[256];
        snprintf(error, sizeof(error), "Duplicate collection '%s'", name);
        yyerror(error);
        return;
    }

    Collection *col = malloc(sizeof(Collection));
    col->name = strdup(name);
    col->members = NULL;
    col->scope_level = scope_level;
    col->next = collection_table;
    collection_table = col;
}

Symbol *find_symbol(const char *name) {
    Symbol *best_match = NULL;
    for (Symbol *sym = symbol_table; sym != NULL; sym = sym->next) {
        if (strcmp(sym->name, name) == 0) {
            if (!best_match || sym->scope_level > best_match->scope_level) {
                best_match = sym;
            }
        }
    }
    return best_match;
}

Function *find_function(const char *name) {
    for (Function *func = function_table; func != NULL; func = func->next) {
        if (strcmp(func->name, name) == 0) {
            return func;
        }
    }
    return NULL;
}

Collection *find_collection(const char *name) {
    for (Collection *col = collection_table; col != NULL; col = col->next) {
        if (strcmp(col->name, name) == 0) {
            return col;
        }
    }
    return NULL;
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <input_file>\n", argv[0]);
        return 1;
    }

    FILE *input = fopen(argv[1], "r");
    if (!input) {
        fprintf(stderr, "Error: Cannot open input file '%s'\n", argv[1]);
        return 1;
    }

    // Set flex to read from input file instead of stdin
    yyin = input;

    printf("Parsing file: %s\n\n", argv[1]);
    int result = yyparse();
    
    printf("\n=== Compilation Statistics ===\n");
    printf("Declarations: %d\n", declarations);
    printf("Assignments: %d\n", assignments);
    printf("Function Calls: %d\n", function_calls);
    printf("Conditions: %d\n", conditions);
    printf("Loops: %d\n", loops);
    
    fclose(input);
    return result;
}

void log_declaration(const char *kind, const char *name, const char *type, const char *value) {
    char indent[256] = "";
    for (int i = 0; i < scope_level; i++) {
        strcat(indent, "  ");
    }
    
    char context[512] = "";
    if (current_function[0] != '\0') {
        sprintf(context, " [in function %s]", current_function);
    }
    
    if (value) {
        printf("Line %d%s: %s%s Declaration: %s of type %s = %s\n", 
               line_number, context, indent, kind, name, type, value);
    } else {
        printf("Line %d%s: %s%s Declaration: %s of type %s\n", 
               line_number, context, indent, kind, name, type);
    }
}

void log_assignment(const char *target, const char *value, const char *type) {
    char indent[256] = "";
    for (int i = 0; i < scope_level; i++) {
        strcat(indent, "  ");
    }
    
    char context[512] = "";
    if (current_function[0] != '\0') {
        sprintf(context, " [in function %s]", current_function);
    }
    
    printf("Line %d%s: %sAssignment: %s = %s (type: %s)\n", 
           line_number, context, indent, target, value, type);
}

void log_operation(const char *op, const char *left, const char *right, const char *result) {
    char indent[256] = "";
    for (int i = 0; i < scope_level; i++) {
        strcat(indent, "  ");
    }
    
    char context[512] = "";
    if (current_function[0] != '\0') {
        sprintf(context, " [in function %s]", current_function);
    }
    
    if (right[0] != '\0') {
        printf("Line %d%s: %sOperation: %s (%s, %s) = %s\n", 
               line_number, context, indent, op, left, right, result);
    } else {
        printf("Line %d%s: %sOperation: %s (%s) = %s\n", 
               line_number, context, indent, op, left, result);
    }
}

void log_function_call(const char *name, int arg_count) {
    char indent[256] = "";
    for (int i = 0; i < scope_level; i++) {
        strcat(indent, "  ");
    }
    
    printf("Line %d: %sFunction Call: %s with %d argument(s)\n", 
           line_number, indent, name, arg_count);
}

void log_condition(const char *type, const char *condition) {
    char indent[256] = "";
    for (int i = 0; i < scope_level; i++) {
        strcat(indent, "  ");
    }
    
    if (condition[0] != '\0') {
        printf("Line %d: %s%s Condition: %s\n", 
               line_number, indent, type, condition);
    } else {
        printf("Line %d: %s%s Branch\n", 
               line_number, indent, type);
    }
}

void log_loop(const char *type, const char *condition) {
    char indent[256] = "";
    for (int i = 0; i < scope_level; i++) {
        strcat(indent, "  ");
    }
    
    printf("Line %d: %s%s: %s\n", 
           line_number, indent, type, condition);
}

void log_collection_access(const char *collection, const char *member) {
    char indent[256] = "";
    for (int i = 0; i < scope_level; i++) {
        strcat(indent, "  ");
    }
    
    printf("Line %d: %sCollection Access: %s.%s\n", 
           line_number, indent, collection, member);
}

void log_array_access(const char *array, const char *index) {
    char indent[256] = "";
    for (int i = 0; i < scope_level; i++) {
        strcat(indent, "  ");
    }
    
    printf("Line %d: %sArray Access: %s[%s]\n", 
           line_number, indent, array, index);
}

void enter_scope(void) {
    scope_level++;
    char indent[256] = "";
    for (int i = 0; i < scope_level; i++) {
        strcat(indent, "  ");
    }
    printf("Line %d: %sEntering scope level %d\n", line_number, indent, scope_level);
}

void exit_scope(void) {
    char indent[256] = "";
    for (int i = 0; i < scope_level; i++) {
        strcat(indent, "  ");
    }
    printf("Line %d: %sExiting scope level %d\n", line_number, indent, scope_level);
    scope_level--;
    if (scope_level == 0) {
        current_function[0] = '\0';
    }
}