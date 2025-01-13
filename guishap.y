%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Structure declarations must come before function declarations
// Symbol table structure
typedef struct Symbol {
    char *name;
    char *type;
    char *value;
    char *function_name;  // Context: which function this belongs to
    char *collection_name;  // Context: which collection this belongs to
    int line_num;
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

// Forward declarations
Collection *find_collection_type(const char *name);
Symbol *find_collection_var(const char *name);

// External declarations for lexer variables
extern int line_number;
extern char *yytext;
extern int yylineno;
extern FILE *yyin;
extern int scope_level;
extern char current_function[256];
extern char current_collection[256];
extern int in_function_params;

// Declaration structure
typedef struct {
    char *name;
    char *type;
    char *value;
    char *function_name;  // Context: which function this belongs to
    char *collection_name;  // Context: which collection this belongs to
    int line_num;
    int is_array;
} Declaration;

// Function to extract declaration info
Declaration* extract_declaration(const char* decl_str, const char* value, int line_num) {
    Declaration* d = malloc(sizeof(Declaration));
    char* temp = strdup(decl_str);
    
    // Check if it's an array
    d->is_array = (strstr(temp, "[]") != NULL);
    
    // Split at '%'
    char* name = strtok(temp, "%");
    char* type = strtok(NULL, "%");
    
    if (type) {
        // Remove [] from type if present
        char* array_marker = strstr(type, "[]");
        if (array_marker) {
            *array_marker = '\0';
        }
        
        d->name = strdup(name);
        d->type = strdup(type);
    } else {
        d->name = strdup(temp);
        d->type = strdup("unknown");
    }
    
    // Store value and line number
    d->value = value ? strdup(value) : NULL;
    d->line_num = line_num;
    
    // Store context
    d->function_name = current_function[0] ? strdup(current_function) : NULL;
    d->collection_name = current_collection[0] ? strdup(current_collection) : NULL;
    
    free(temp);
    return d;
}

void free_declaration(Declaration* d) {
    if (d) {
        free(d->name);
        free(d->type);
        if (d->value) free(d->value);
        if (d->function_name) free(d->function_name);
        if (d->collection_name) free(d->collection_name);
        free(d);
    }
}

// Function declarations
int yylex(void);
void yyerror(const char *s);

// Global symbol tables
Symbol *symbol_table = NULL;
Function *function_table = NULL;
Collection *collection_table = NULL;

// Statistics
int declarations = 0;
int assignments = 0;
int function_calls = 0;
int conditions = 0;
int loops = 0;

// Helper functions
void enter_scope(void);
void exit_scope(void);
void add_symbol(const char *name, const char *type, int is_const, int is_array, const char *value, int line_num);
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
void log_case(const char *type, const char *value);

// Helper function to check if a type is valid
int is_valid_type(const char* type) {
    // Check primitive types
    if (strcmp(type, "int") == 0 || 
        strcmp(type, "float") == 0 || 
        strcmp(type, "string") == 0 || 
        strcmp(type, "bool") == 0 || 
        strcmp(type, "void") == 0) {
        return 1;
    }
    
    // Check if it's a defined collection type
    Collection* col = find_collection_type(type);
    if (col) {
        return 1;
    }
    
    return 0;
}

// Rename existing find_collection to find_collection_type for clarity
Collection *find_collection_type(const char *name) {
    for (Collection *col = collection_table; col != NULL; col = col->next) {
        if (strcmp(col->name, name) == 0) {
            return col;
        }
    }
    return NULL;
}

// Add new function to find collection-typed variables
Symbol *find_collection_var(const char *name) {
    Symbol *sym = find_symbol(name);
    if (!sym) return NULL;
    
    // Check if the symbol's type is a collection
    Collection *col_type = find_collection_type(sym->type);
    if (!col_type) return NULL;
    
    return sym;
}

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
%type <sval> block case_list case_item case_value argument_list
%type <sval> assignment collection_init member_assignments member_assignment array_values
%type <sval> array_expression collection_expression function_expression
%type <sval> range_expression

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
        Declaration* d = extract_declaration($1, NULL, line_number);
        if (!is_valid_type(d->type)) {
            char error[256];
            snprintf(error, sizeof(error), "Undefined type '%s'", d->type);
            yyerror(error);
            free_declaration(d);
            YYERROR;
        }
        $$.name = d->name;
        $$.type = d->type;
        add_symbol(d->name, d->type, 0, d->is_array, NULL, line_number);
        declarations++;
        log_declaration("Variable", d->name, d->type, NULL);
        free_declaration(d);
    }
    | CONST_DECL {
        Declaration* d = extract_declaration($1, NULL, line_number);
        if (!is_valid_type(d->type)) {
            char error[256];
            snprintf(error, sizeof(error), "Undefined type '%s'", d->type);
            yyerror(error);
            free_declaration(d);
            YYERROR;
        }
        $$.name = d->name;
        $$.type = d->type;
        add_symbol(d->name, d->type, 1, d->is_array, NULL, line_number);
        declarations++;
        log_declaration("Constant", d->name, d->type, NULL);
        free_declaration(d);
    }
    | ARRAY_DECL {
        Declaration* d = extract_declaration($1, NULL, line_number);
        if (!is_valid_type(d->type)) {
            char error[256];
            snprintf(error, sizeof(error), "Undefined type '%s'", d->type);
            yyerror(error);
            free_declaration(d);
            YYERROR;
        }
        $$.name = d->name;
        $$.type = d->type;
        add_symbol(d->name, d->type, 0, 1, NULL, line_number);
        declarations++;
        log_declaration("Array", d->name, d->type, NULL);
        free_declaration(d);
    }
    | VAR_DECL ASSIGN expression {
        Declaration* d = extract_declaration($1, $3, line_number);
        if (!is_valid_type(d->type)) {
            char error[256];
            snprintf(error, sizeof(error), "Undefined type '%s'", d->type);
            yyerror(error);
            free_declaration(d);
            YYERROR;
        }
        $$.name = d->name;
        $$.type = d->type;
        add_symbol(d->name, d->type, 0, d->is_array, $3, line_number);
        declarations++;
        assignments++;
        log_declaration("Variable", d->name, d->type, $3);
        free_declaration(d);
    }
    | CONST_DECL ASSIGN expression {
        Declaration* d = extract_declaration($1, $3, line_number);
        if (!is_valid_type(d->type)) {
            char error[256];
            snprintf(error, sizeof(error), "Undefined type '%s'", d->type);
            yyerror(error);
            free_declaration(d);
            YYERROR;
        }
        $$.name = d->name;
        $$.type = d->type;
        add_symbol(d->name, d->type, 1, d->is_array, $3, line_number);
        declarations++;
        assignments++;
        log_declaration("Constant", d->name, d->type, $3);
        free_declaration(d);
    }
    | ARRAY_DECL ASSIGN '[' array_values ']' {
        Declaration* d = extract_declaration($1, NULL, line_number);
        if (!is_valid_type(d->type)) {
            char error[256];
            snprintf(error, sizeof(error), "Undefined type '%s'", d->type);
            yyerror(error);
            free_declaration(d);
            YYERROR;
        }
        if (!d->is_array) {
            char error[256];
            snprintf(error, sizeof(error), "Cannot initialize non-array variable '%s' with array values", d->name);
            yyerror(error);
            free_declaration(d);
            YYERROR;
        }
        $$.name = d->name;
        $$.type = d->type;
        add_symbol(d->name, d->type, 0, 1, "array initializer", line_number);
        declarations++;
        assignments++;
        log_declaration("Array", d->name, d->type, "array initializer");
        free_declaration(d);
    }
    ;

collection_definition
    : COL IDENTIFIER { 
        enter_scope(); 
        strncpy(current_collection, $2, sizeof(current_collection)-1);
        print_scope_info("Collection Start", $2); 
    }
    '{' member_list '}' ';' {
        add_collection($2);
        print_scope_info("Collection End", $2);
        current_collection[0] = '\0';
        exit_scope();
    }
    ;

member_list
    : member                        { $$ = $1; }
    | member_list ',' member        { $$ = $3; }
    ;

member
    : VAR_DECL                     { 
        Declaration* d = extract_declaration($1, NULL, line_number);
        $$ = d->name;
        add_symbol(d->name, d->type, 0, d->is_array, NULL, line_number);
        char info[256];
        sprintf(info, "Collection Member: %s of type %s", d->name, d->type);
        print_scope_info("Collection Member", info);
        free_declaration(d);
    }
    | ARRAY_DECL                   { 
        Declaration* d = extract_declaration($1, NULL, line_number);
        $$ = d->name;
        add_symbol(d->name, d->type, 0, 1, NULL, line_number);
        char info[256];
        sprintf(info, "Collection Array Member: %s of type %s", d->name, d->type);
        print_scope_info("Collection Array Member", info);
        free_declaration(d);
    }
    ;

function_definition
    : SHAP IDENTIFIER { 
        enter_scope(); 
        strncpy(current_function, $2, sizeof(current_function)-1);
        print_scope_info("Function Start", $2);
        in_function_params = 1;  // Set when starting parameter list
    }
    '(' parameter_list ')' { 
        in_function_params = 0;  // Clear after parameter list
    } '>' type block {
        add_function($2, $9);
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
        Declaration* d = extract_declaration($1, NULL, line_number);
        $$ = d->name;
        add_symbol(d->name, d->type, 0, d->is_array, NULL, line_number);
        char info[256];
        sprintf(info, "Parameter: %s of type %s", d->name, d->type);
        print_scope_info("Parameter", info);
        free_declaration(d);
    }
    | ARRAY_DECL                   { 
        Declaration* d = extract_declaration($1, NULL, line_number);
        $$ = d->name;
        add_symbol(d->name, d->type, 0, 1, NULL, line_number);
        char info[256];
        sprintf(info, "Array Parameter: %s of type %s", d->name, d->type);
        print_scope_info("Array Parameter", info);
        free_declaration(d);
    }
    | CONST_DECL ASSIGN expression { 
        Declaration* d = extract_declaration($1, $3, line_number);
        $$ = d->name;
        add_symbol(d->name, d->type, 1, d->is_array, $3, line_number);
        char info[256];
        sprintf(info, "Constant Parameter: %s of type %s = %s", d->name, d->type, $3);
        print_scope_info("Constant Parameter", info);
        free_declaration(d);
    }
    | CONST_DECL ASSIGN '[' array_values ']' {
        Declaration* d = extract_declaration($1, NULL, line_number);
        $$ = d->name;
        add_symbol(d->name, d->type, 1, 1, "array initializer", line_number);
        char info[256];
        sprintf(info, "Constant Array Parameter: %s of type %s", d->name, d->type);
        print_scope_info("Constant Array Parameter", info);
        free_declaration(d);
    }
    | CONST_DECL error {
        char error[256];
        snprintf(error, sizeof(error), "Constant declaration must be followed by an assignment");
        yyerror(error);
        YYERROR;
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
            } else if (sym->is_array) {
                yyerror("Cannot assign scalar value to array");
            } else {
                // Update the symbol's value
                if (sym->value) free(sym->value);
                sym->value = strdup($3);
                assignments++;
                log_assignment($1, $3, sym->type);
            }
        } else {
            char error[256];
            snprintf(error, sizeof(error), "Undefined variable '%s'", $1);
            yyerror(error);
        }
        $$ = "assignment";
    }
    | IDENTIFIER '[' expression ']' ASSIGN expression {
        Symbol *sym = find_symbol($1);
        if (sym) {
            if (!sym->is_array) {
                char error[256];
                snprintf(error, sizeof(error), "'%s' is not an array", $1);
                yyerror(error);
            } else {
                assignments++;
                log_array_access($1, $3);
                log_assignment($1, $6, sym->type);
            }
        } else {
            char error[256];
            snprintf(error, sizeof(error), "Undefined array '%s'", $1);
            yyerror(error);
        }
        $$ = "array_assignment";
    }
    | IDENTIFIER '.' IDENTIFIER ASSIGN expression {
        Symbol *sym = find_collection_var($1);
        if (!sym) {
            Symbol *var = find_symbol($1);
            if (!var) {
                char error[256];
                snprintf(error, sizeof(error), "Undefined identifier '%s'", $1);
                yyerror(error);
            } else {
                char error[256];
                snprintf(error, sizeof(error), "Variable '%s' of type '%s' is not a collection", $1, var->type);
                yyerror(error);
            }
            YYERROR;
        }
        
        // Check if member exists in collection type
        Collection *col_type = find_collection_type(sym->type);
        int found = 0;
        Symbol *member = NULL;
        for (Symbol *s = symbol_table; s != NULL; s = s->next) {
            if (s->collection_name && strcmp(s->collection_name, col_type->name) == 0 && 
                strcmp(s->name, $3) == 0) {
                found = 1;
                member = s;
                break;
            }
        }
        if (!found) {
            char error[256];
            snprintf(error, sizeof(error), "Member '%s' not found in collection type '%s'", $3, sym->type);
            yyerror(error);
            YYERROR;
        }
        if (member->is_array) {
            yyerror("Cannot assign scalar value to array member");
            YYERROR;
        }
        assignments++;
        log_collection_access($1, $3);
        log_assignment($3, $5, member->type);
        $$ = "member_assignment";
    }
    | IDENTIFIER '.' IDENTIFIER ASSIGN '[' array_values ']' {
        Symbol *sym = find_collection_var($1);
        if (!sym) {
            Symbol *var = find_symbol($1);
            if (!var) {
                char error[256];
                snprintf(error, sizeof(error), "Undefined identifier '%s'", $1);
                yyerror(error);
            } else {
                char error[256];
                snprintf(error, sizeof(error), "Variable '%s' of type '%s' is not a collection", $1, var->type);
                yyerror(error);
            }
            YYERROR;
        }
        
        // Check if member exists in collection type
        Collection *col_type = find_collection_type(sym->type);
        int found = 0;
        Symbol *member = NULL;
        for (Symbol *s = symbol_table; s != NULL; s = s->next) {
            if (s->collection_name && strcmp(s->collection_name, col_type->name) == 0 && 
                strcmp(s->name, $3) == 0) {
                found = 1;
                member = s;
                break;
            }
        }
        if (!found) {
            char error[256];
            snprintf(error, sizeof(error), "Member '%s' not found in collection type '%s'", $3, sym->type);
            yyerror(error);
            YYERROR;
        }
        if (!member->is_array) {
            char error[256];
            snprintf(error, sizeof(error), "Member '%s' is not an array", $3);
            yyerror(error);
            YYERROR;
        }
        assignments++;
        log_collection_access($1, $3);
        log_assignment($3, "array values", member->type);
        $$ = "array_member_assignment";
    }
    | IDENTIFIER ASSIGN collection_init {
        Symbol *sym = find_collection_var($1);
        if (!sym) {
            Symbol *var = find_symbol($1);
            if (!var) {
                char error[256];
                snprintf(error, sizeof(error), "Undefined variable '%s'", $1);
                yyerror(error);
            } else {
                char error[256];
                snprintf(error, sizeof(error), "Variable '%s' of type '%s' is not a collection", $1, var->type);
                yyerror(error);
            }
            YYERROR;
        }
        
        assignments++;
        log_assignment($1, "collection initializer", sym->type);
        $$ = "collection_assignment";
    }
    | IDENTIFIER ASSIGN '[' array_values ']' {
        Symbol *sym = find_symbol($1);
        if (!sym) {
            char error[256];
            snprintf(error, sizeof(error), "Undefined variable '%s'", $1);
            yyerror(error);
            YYERROR;
        }
        if (!sym->is_array) {
            char error[256];
            snprintf(error, sizeof(error), "Variable '%s' is not an array", $1);
            yyerror(error);
            YYERROR;
        }
        assignments++;
        log_assignment($1, "array values", sym->type);
        $$ = "array_assignment";
    }
    ;

collection_init
    : '{' member_assignments '}'          { $$ = "collection_init"; }
    ;

member_assignments
    : member_assignment                    { $$ = $1; }
    | member_assignments ',' member_assignment { $$ = $3; }
    ;

member_assignment
    : IDENTIFIER ASSIGN expression {
        Symbol *current = find_symbol($<sval>0);  // Get the collection variable being initialized
        if (!current) {
            yyerror("Invalid collection initialization context");
            YYERROR;
        }
        
        Collection *col = find_collection(current->type);
        if (!col) {
            yyerror("Invalid collection type");
            YYERROR;
        }
        
        // Check if member exists in collection
        int found = 0;
        for (Symbol *s = symbol_table; s != NULL; s = s->next) {
            if (s->collection_name && strcmp(s->collection_name, col->name) == 0 && 
                strcmp(s->name, $1) == 0) {
                found = 1;
                assignments++;
                log_assignment($1, $3, s->type);
                break;
            }
        }
        
        if (!found) {
            char error[256];
            snprintf(error, sizeof(error), "Member '%s' not found in collection type '%s'", 
                    $1, col->name);
            yyerror(error);
            YYERROR;
        }
    }
    | IDENTIFIER ASSIGN '[' array_values ']' {
        Symbol *current = find_symbol($<sval>0);  // Get the collection variable being initialized
        if (!current) {
            yyerror("Invalid collection initialization context");
            YYERROR;
        }
        
        Collection *col = find_collection(current->type);
        if (!col) {
            yyerror("Invalid collection type");
            YYERROR;
        }
        
        // Check if array member exists in collection
        int found = 0;
        for (Symbol *s = symbol_table; s != NULL; s = s->next) {
            if (s->collection_name && strcmp(s->collection_name, col->name) == 0 && 
                strcmp(s->name, $1) == 0) {
                if (!s->is_array) {
                    char error[256];
                    snprintf(error, sizeof(error), "Member '%s' in collection '%s' is not an array", 
                            $1, col->name);
                    yyerror(error);
                    YYERROR;
                }
                found = 1;
                assignments++;
                log_assignment($1, "array initializer", s->type);
                break;
            }
        }
        
        if (!found) {
            char error[256];
            snprintf(error, sizeof(error), "Member '%s' not found in collection type '%s'", 
                    $1, col->name);
            yyerror(error);
            YYERROR;
        }
    }
    ;

array_values
    : expression                          { $$ = $1; }
    | array_values ',' expression         { $$ = $3; }
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
    | LOOP VAR_DECL FOR range_expression { 
        // Case 1: Iterator declared in loop
        Declaration* d = extract_declaration($2, NULL, line_number);
        add_symbol(d->name, d->type, 0, d->is_array, NULL, line_number);
        char info[512];
        sprintf(info, "Loop Iterator: %s of type %s, %s", d->name, d->type, $4);
        log_loop("Loop For", info);
        enter_scope();
        free_declaration(d);
        free($4);  // Free the range expression string
    } block { 
        loops++;
        exit_scope();
    }
    | LOOP IDENTIFIER FOR range_expression {
        // Case 2: Using existing variable as iterator
        Symbol *sym = find_symbol($2);
        if (!sym) {
            char error[256];
            snprintf(error, sizeof(error), "Undefined iterator variable '%s'", $2);
            yyerror(error);
            YYERROR;
        } else {
            char info[512];
            sprintf(info, "Loop Iterator: %s (existing variable), %s", $2, $4);
            log_loop("Loop For", info);
        }
        enter_scope();
        free($4);  // Free the range expression string
    } block {
        loops++;
        exit_scope();
    }
    ;

range_expression
    : '[' expression RANGE expression ']' {
        char* result = malloc(strlen($2) + strlen($4) + 20);
        sprintf(result, "Range: from %s to %s", $2, $4);
        $$ = result;
    }
    | '[' expression RANGE expression RANGE expression ']' {
        char* result = malloc(strlen($2) + strlen($4) + strlen($6) + 30);
        sprintf(result, "Range: from %s to %s, step %s", $2, $4, $6);
        $$ = result;
    }
    ;

case_statement
    : CASE '[' expression ']' { 
        log_condition("Case Switch", $3); 
    } '{' case_list '}' {
        print_scope_info("Case End", "");
    }
    ;

case_list
    : case_item                    { $$ = $1; }
    | case_list case_item         { $$ = $2; }
    ;

case_item
    : '[' case_value ']' { enter_scope(); } block { 
        char info[256];
        sprintf(info, "Case Value: %s", $2);
        log_case("Case Branch", info);
        $$ = "case";
        exit_scope();
        free($2);  // Free the strdup'd value
    }
    | '[' ']' { enter_scope(); } block { 
        log_case("Default Case", "");
        $$ = "default";
        exit_scope();
    }
    ;

case_value
    : INTEGER                      { char buf[32]; sprintf(buf, "%d", $1); $$ = strdup(buf); }
    | FLOAT                       { char buf[32]; sprintf(buf, "%.1f", $1); $$ = strdup(buf); }
    | STRING                      { $$ = strdup($1); }
    | IDENTIFIER                  { 
        Symbol *sym = find_symbol($1);
        if (!sym) {
            char error[256];
            snprintf(error, sizeof(error), "Undefined identifier '%s' in case value", $1);
            yyerror(error);
            $$ = "error";
        } else {
            $$ = strdup($1);
        }
    }
    ;

expression
    : INTEGER                      { char buf[32]; sprintf(buf, "%d", $1); $$ = strdup(buf); }
    | FLOAT                       { char buf[32]; sprintf(buf, "%g", $1); $$ = strdup(buf); }
    | STRING                      { $$ = $1; }
    | array_expression            { $$ = $1; }
    | collection_expression       { $$ = $1; }
    | function_expression         { $$ = $1; }
    | '(' expression ')'          { $$ = $2; }
    | expression '+' expression   { log_operation("Addition", $1, $3, "result"); 
                                        char* result = malloc(strlen($1) + strlen($3) + 2);
                                        sprintf(result, "%s + %s", $1, $3);
                                        $$ = result;
                                    }
    | expression '-' expression   { log_operation("Subtraction", $1, $3, "result");
                                        char* result = malloc(strlen($1) + strlen($3) + 2);
                                        sprintf(result, "%s - %s", $1, $3);
                                        $$ = result;
                                    }
    | expression '*' expression   { log_operation("Multiplication", $1, $3, "result");
                                        char* result = malloc(strlen($1) + strlen($3) + 2);
                                        sprintf(result, "%s * %s", $1, $3);
                                        $$ = result;
                                    }
    | expression '/' expression   { log_operation("Division", $1, $3, "result");
                                        char* result = malloc(strlen($1) + strlen($3) + 2);
                                        sprintf(result, "%s / %s", $1, $3);
                                        $$ = result;
                                    }
    | expression '%' expression   { log_operation("Modulo", $1, $3, "result");
                                        char* result = malloc(strlen($1) + strlen($3) + 2);
                                        sprintf(result, "%s % %s", $1, $3);
                                        $$ = result;
                                    }
    | expression '&' expression   { log_operation("Bitwise AND", $1, $3, "result");
                                        char* result = malloc(strlen($1) + strlen($3) + 2);
                                        sprintf(result, "%s & %s", $1, $3);
                                        $$ = result;
                                    }
    | expression '|' expression   { log_operation("Bitwise OR", $1, $3, "result");
                                        char* result = malloc(strlen($1) + strlen($3) + 2);
                                        sprintf(result, "%s | %s", $1, $3);
                                        $$ = result;
                                    }
    | expression '^' expression   { log_operation("Bitwise XOR", $1, $3, "result");
                                        char* result = malloc(strlen($1) + strlen($3) + 2);
                                        sprintf(result, "%s ^ %s", $1, $3);
                                        $$ = result;
                                    }
    | '~' expression             { log_operation("Bitwise NOT", $2, "", "result");
                                        char* result = malloc(strlen($2) + 2);
                                        sprintf(result, "~%s", $2);
                                        $$ = result;
                                    }
    | expression EQ expression    { log_operation("Equals", $1, $3, "result");
                                        char* result = malloc(strlen($1) + strlen($3) + 2);
                                        sprintf(result, "%s == %s", $1, $3);
                                        $$ = result;
                                        }
    | expression LT expression    { log_operation("Less Than", $1, $3, "result");
                                        char* result = malloc(strlen($1) + strlen($3) + 2);
                                        sprintf(result, "%s < %s", $1, $3);
                                        $$ = result;
                                    }
    | expression GT expression    { log_operation("Greater Than", $1, $3, "result");
                                        char* result = malloc(strlen($1) + strlen($3) + 2);
                                        sprintf(result, "%s > %s", $1, $3);
                                        $$ = result;
                                    }
    | expression LE expression    { log_operation("Less Equal", $1, $3, "result"); 
                                        char* result = malloc(strlen($1) + strlen($3) + 2);
                                        sprintf(result, "%s <= %s", $1, $3);
                                        $$ = result;
                                    }
    | expression GE expression    { log_operation("Greater Equal", $1, $3, "result");
                                        char* result = malloc(strlen($1) + strlen($3) + 2);
                                        sprintf(result, "%s >= %s", $1, $3);
                                        $$ = result;
                                    }
    | expression AND expression   { log_operation("Logical AND", $1, $3, "result");
                                        char* result = malloc(strlen($1) + strlen($3) + 2);
                                        sprintf(result, "%s && %s", $1, $3);
                                        $$ = result;
                                    }
    | expression OR expression    { log_operation("Logical OR", $1, $3, "result");
                                            char* result = malloc(strlen($1) + strlen($3) + 2);
                                        sprintf(result, "%s || %s", $1, $3);
                                        $$ = result;
                                    }
    | NOT expression             { log_operation("Logical NOT", $2, "", "result");
                                        char* result = malloc(strlen($2) + 2);
                                        sprintf(result, "!%s", $2);
                                        $$ = result;
                                    }
    | '-' expression %prec UMINUS { log_operation("Negation", $2, "", "result");
                                        char* result = malloc(strlen($2) + 2);
                                        sprintf(result, "-%s", $2);
                                        $$ = result;
                                    }
    | IDENTIFIER                  { 
        Symbol *sym = find_symbol($1);
        if (!sym) {
            char error[256];
            snprintf(error, sizeof(error), "Undefined identifier '%s'", $1);
            yyerror(error);
            YYERROR;
        }
        $$ = $1;
    }
    ;

array_expression
    : IDENTIFIER '[' expression ']' { 
        Symbol *sym = find_symbol($1);
        if (!sym) {
            char error[256];
            snprintf(error, sizeof(error), "Undefined array '%s'", $1);
            yyerror(error);
            YYERROR;
        }
        if (!sym->is_array) {
            char error[256];
            snprintf(error, sizeof(error), "'%s' is not an array", $1);
            yyerror(error);
            YYERROR;
        }
        log_array_access($1, $3);
        $$ = $1;
    }
    | collection_expression '[' expression ']' {
        // Handle array access on collection members
        if (!strstr($1, ".")) {
            char error[256];
            snprintf(error, sizeof(error), "Invalid array access on non-member expression");
            yyerror(error);
            YYERROR;
        }
        // The collection member check is already done in collection_expression
        log_array_access($1, $3);
        $$ = $1;
    }
    ;

collection_expression
    : IDENTIFIER '.' IDENTIFIER   { 
        Symbol *sym = find_collection_var($1);
        if (!sym) {
            Symbol *var = find_symbol($1);
            if (!var) {
                char error[256];
                snprintf(error, sizeof(error), "Undefined identifier '%s'", $1);
                yyerror(error);
            } else {
                char error[256];
                snprintf(error, sizeof(error), "Variable '%s' of type '%s' is not a collection", $1, var->type);
                yyerror(error);
            }
            YYERROR;
        }
        
        // Check if member exists in collection type
        Collection *col_type = find_collection_type(sym->type);
        Symbol *member = NULL;
        int found = 0;
        for (Symbol *s = symbol_table; s != NULL; s = s->next) {
            if (s->collection_name && strcmp(s->collection_name, col_type->name) == 0 && 
                strcmp(s->name, $3) == 0) {
                found = 1;
                member = s;
                break;
            }
        }
        if (!found) {
            char error[256];
            snprintf(error, sizeof(error), "Member '%s' not found in collection type '%s'", $3, sym->type);
            yyerror(error);
            YYERROR;
        }
        log_collection_access($1, $3);
        char *result = malloc(strlen($1) + strlen($3) + 2);
        sprintf(result, "%s.%s", $1, $3);
        $$ = result;
    }
    ;

function_expression
    : IDENTIFIER '(' argument_list ')' { 
        Function *func = find_function($1);
        if (!func) {
            char error[256];
            snprintf(error, sizeof(error), "Undefined function '%s'", $1);
            yyerror(error);
            YYERROR;
        }
        function_calls++;
        log_function_call($1, 1); // TODO: Count actual arguments
        $$ = $1;
    }
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

    
    printf("Line %d%s: %s%s: %s\n", line_number, context, indent, action, details);
}

void add_symbol(const char *name, const char *type, int is_const, int is_array, const char *value, int line_num) {
    // For collection members, only check duplicates within the same collection
    if (current_collection[0] != '\0') {
        for (Symbol *sym = symbol_table; sym != NULL; sym = sym->next) {
            if (sym->scope_level == scope_level && 
                strcmp(sym->name, name) == 0 && 
                sym->collection_name && 
                strcmp(sym->collection_name, current_collection) == 0) {
                char error[256];
                snprintf(error, sizeof(error), "Duplicate member '%s' in collection '%s'", 
                        name, current_collection);
                yyerror(error);
                return;
            }
        }
    } 
    // For function parameters, only check duplicates in parameter list
    else if (current_function[0] != '\0' && in_function_params) {
        for (Symbol *sym = symbol_table; sym != NULL; sym = sym->next) {
            if (sym->scope_level == scope_level && 
                strcmp(sym->name, name) == 0 && 
                sym->function_name &&
                strcmp(sym->function_name, current_function) == 0) {
                char error[256];
                snprintf(error, sizeof(error), "Duplicate parameter '%s' in function '%s'", 
                        name, current_function);
                yyerror(error);
                return;
            }
        }
    }
    else {
        // For regular variables, check duplicates in current and parent scopes
        for (Symbol *sym = symbol_table; sym != NULL; sym = sym->next) {
            if (sym->scope_level <= scope_level && strcmp(sym->name, name) == 0) {
                char error[256];
                snprintf(error, sizeof(error), "Duplicate identifier '%s' in current scope", name);
                yyerror(error);
                return;
            }
        }
    }

    Symbol *sym = malloc(sizeof(Symbol));
    sym->name = strdup(name);
    sym->type = strdup(type);
    sym->value = value ? strdup(value) : NULL;
    sym->line_num = line_num;
    sym->is_const = is_const;
    sym->is_array = is_array;
    sym->scope_level = scope_level;
    sym->function_name = current_function[0] ? strdup(current_function) : NULL;
    sym->collection_name = current_collection[0] ? strdup(current_collection) : NULL;
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

    
    printf("Line %d%s: %sAssignment: %s = %s (type: %s)\n", 
           line_number, context, indent, target, value, type);
}

void log_operation(const char *op, const char *left, const char *right, const char *result) {
    char indent[256] = "";
    for (int i = 0; i < scope_level; i++) {
        strcat(indent, "  ");
    }
    
    char context[512] = "";

    
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

void log_case(const char *type, const char *value) {
    char indent[256] = "";
    for (int i = 0; i < scope_level; i++) {
        strcat(indent, "  ");
    }
    
    char context[512] = "";
    if (current_function[0] != '\0') {
        sprintf(context, "", current_function);
    }
    
    if (value && value[0] != '\0') {
        printf("Line %d%s: %s%s: %s\n", 
               line_number, context, indent, type, value);
    } else {
        printf("Line %d%s: %s%s\n", 
               line_number, context, indent, type);
    }
}