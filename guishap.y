%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

// Add global file pointer for output
FILE* output_file = NULL;

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
    int is_temporary;     // For function parameters and loop iterators
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

Collection *find_collection_type(const char *name);
Symbol *find_collection_var(const char *name);

extern int line_number;
extern char *yytext;
extern int yylineno;
extern FILE *yyin;
extern int scope_level;
extern char current_function[256];
extern char current_collection[256];
extern int in_function_params;

typedef struct {
    char *name;
    char *type;
    char *value;
    char *function_name;  // Context: which function this belongs to
    char *collection_name;  // Context: which collection this belongs to
    int line_num;
    int is_array;
} Declaration;

Declaration* extract_declaration(const char* decl_str, const char* value, int line_num) {
    Declaration* d = malloc(sizeof(Declaration));
    char* temp = strdup(decl_str);
    
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
    
    d->value = value ? strdup(value) : NULL;
    d->line_num = line_num;
    
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

int yylex(void);
void yyerror(const char *s);

Symbol *symbol_table = NULL;
Function *function_table = NULL;
Collection *collection_table = NULL;

int declarations = 0;
int assignments = 0;
int function_calls = 0;
int conditions = 0;
int loops = 0;

void enter_scope(void);
void exit_scope(void);
void cleanup_temporary_symbols(int scope);
void add_symbol(const char *name, const char *type, int is_const, int is_array, const char *value, int line_num, int is_temporary);
void add_function(const char *name, const char *return_type);
void add_collection(const char *name);
Symbol *find_symbol(const char *name);
Function *find_function(const char *name);
Collection *find_collection(const char *name);
void print_scope_info(const char *action, const char *details);

void log_declaration(const char *kind, const char *name, const char *type, const char *value);
void log_assignment(const char *target, const char *value, const char *type);
void log_operation(const char *op, const char *left, const char *right, const char *result);
void log_function_call(const char *name, int arg_count);
void log_condition(const char *type, const char *condition);
void log_loop(const char *type, const char *condition);
void log_collection_access(const char *collection, const char *member);
void log_array_access(const char *array, const char *index);
void log_case(const char *type, const char *value);

int is_valid_type(const char* type) {
    // Check primitive types
    if (strcmp(type, "int") == 0 || 
        strcmp(type, "float") == 0 || 
        strcmp(type, "string") == 0 || 
        strcmp(type, "bool") == 0 || 
        strcmp(type, "void") == 0) {
        return 1;
    }
   
    Collection* col = find_collection_type(type);
    if (col) {
        return 1;
    }
    
    return 0;
}

// Add function to check for reserved keywords
int is_reserved_keyword(const char* name) {
    const char* keywords[] = {
        "int", "float", "string", "bool", "void",  // Types
        "col", "shap", "ret",                      // Definition keywords
        "loop", "till", "for",                     // Loop keywords
        "break", "continue",                       // Control flow
        "if", "elif", "else", "case",             // Conditional keywords
        "true", "false",                          // Boolean literals
        NULL
    };
    
    for (const char** keyword = keywords; *keyword != NULL; keyword++) {
        if (strcmp(name, *keyword) == 0) {
            return 1;
        }
    }
    return 0;
}

// Helper function to validate identifier name
int validate_identifier(const char* name, const char* context) {
    if (is_reserved_keyword(name)) {
        char error[256];
        snprintf(error, sizeof(error), "Cannot use reserved keyword '%s' as %s name", name, context);
        yyerror(error);
        return 0;
    }
    return 1;
}

Collection *find_collection_type(const char *name) {
    for (Collection *col = collection_table; col != NULL; col = col->next) {
        if (strcmp(col->name, name) == 0) {
            return col;
        }
    }
    return NULL;
}

Symbol *find_collection_var(const char *name) {
    Symbol *sym = find_symbol(name);
    if (!sym) return NULL;
    
    // Check if the symbol's type is a collection
    Collection *col_type = find_collection_type(sym->type);
    if (!col_type) return NULL;
    
    return sym;
}

int are_types_compatible(const char* type1, const char* type2) {
    if (!type1 || !type2) return 0;
    if (strcmp(type1, type2) == 0) return 1;
    
    // Allow int to float and float to int conversion
    if ((strcmp(type1, "int") == 0 && strcmp(type2, "float") == 0) ||
        (strcmp(type1, "float") == 0 && strcmp(type2, "int") == 0)) {
        return 1;
    }
    
    return 0;
}

char* get_result_type(const char* op, const char* type1, const char* type2) {
    if (!type1 || !type2) return NULL;
    
    // Arithmetic operators
    if (strcmp(op, "+") == 0 || strcmp(op, "-") == 0 || 
        strcmp(op, "*") == 0 || strcmp(op, "/") == 0) {
        if (strcmp(type1, "string") == 0 || strcmp(type2, "string") == 0) {
            return NULL;  // String arithmetic not allowed
        }
        if (strcmp(type1, "float") == 0 || strcmp(type2, "float") == 0) {
            return "float";
        }
        return "int";
    }
    
    // Modulo operator
    if (strcmp(op, "%") == 0) {
        if (strcmp(type1, "int") == 0 && strcmp(type2, "int") == 0) {
            return "int";
        }
        return NULL;  // Modulo only works with integers
    }
    
    // Comparison operators
    if (strcmp(op, "==") == 0 || strcmp(op, "<") == 0 || 
        strcmp(op, ">") == 0 || strcmp(op, "<=") == 0 || 
        strcmp(op, ">=") == 0) {
        if (are_types_compatible(type1, type2)) {
            return "bool";
        }
        return NULL;
    }
    
    // Logical operators
    if (strcmp(op, "&&") == 0 || strcmp(op, "||") == 0) {
        if (strcmp(type1, "bool") == 0 && strcmp(type2, "bool") == 0) {
            return "bool";
        }
        return NULL;
    }
    
    // Bitwise operators
    if (strcmp(op, "&") == 0 || strcmp(op, "|") == 0 || strcmp(op, "^") == 0) {
        if (strcmp(type1, "int") == 0 && strcmp(type2, "int") == 0) {
            return "int";
        }
        return NULL;
    }
    
    return NULL;
}


// Type checking helper functions
char* get_expression_type(const char* expr) {
    if (!expr) {
        return NULL;
    }
    
    // Trim leading and trailing whitespace
    while (*expr && isspace(*expr)) expr++;
    if (!*expr) return NULL;
    
    // Check if it's a literal
    if (expr[0] == '"') {
        return strdup("string");
    }
    
    // Check if it's a compound expression with operators
    char* plus = strstr(expr, " + ");
    char* minus = strstr(expr, " - ");
    char* mult = strstr(expr, " * ");
    char* div = strstr(expr, " / ");
    char* mod = strstr(expr, " % ");
    char* and = strstr(expr, " && ");
    char* or = strstr(expr, " || ");
    char* eq = strstr(expr, " == ");
    char* lt = strstr(expr, " < ");
    char* gt = strstr(expr, " > ");
    char* le = strstr(expr, " <= ");
    char* ge = strstr(expr, " >= ");
    char* bitand = strstr(expr, " & ");
    char* bitor = strstr(expr, " | ");
    char* bitxor = strstr(expr, " ^ ");
    
    if (plus || minus || mult || div || mod || and || or || eq || lt || gt || le || ge || 
        bitand || bitor || bitxor) {
        // Find the leftmost operator
        char* operator_pos = NULL;
        char* op = NULL;
        
        if (plus && (!operator_pos || plus < operator_pos)) { operator_pos = plus; op = "+"; }
        if (minus && (!operator_pos || minus < operator_pos)) { operator_pos = minus; op = "-"; }
        if (mult && (!operator_pos || mult < operator_pos)) { operator_pos = mult; op = "*"; }
        if (div && (!operator_pos || div < operator_pos)) { operator_pos = div; op = "/"; }
        if (mod && (!operator_pos || mod < operator_pos)) { operator_pos = mod; op = "%"; }
        if (and && (!operator_pos || and < operator_pos)) { operator_pos = and; op = "&&"; }
        if (or && (!operator_pos || or < operator_pos)) { operator_pos = or; op = "||"; }
        if (eq && (!operator_pos || eq < operator_pos)) { operator_pos = eq; op = "=="; }
        if (le && (!operator_pos || le < operator_pos)) { operator_pos = le; op = "<="; }
        if (ge && (!operator_pos || ge < operator_pos)) { operator_pos = ge; op = ">="; }
        if (lt && (!operator_pos || lt < operator_pos)) { operator_pos = lt; op = "<"; }
        if (gt && (!operator_pos || gt < operator_pos)) { operator_pos = gt; op = ">"; }
        if (bitand && (!operator_pos || bitand < operator_pos)) { operator_pos = bitand; op = "&"; }
        if (bitor && (!operator_pos || bitor < operator_pos)) { operator_pos = bitor; op = "|"; }
        if (bitxor && (!operator_pos || bitxor < operator_pos)) { operator_pos = bitxor; op = "^"; }
        
        if (operator_pos) {
            // Split at the operator position
            char* expr_copy = strdup(expr);
            operator_pos = expr_copy + (operator_pos - expr);  // Adjust pointer to the copy
            *operator_pos = '\0';
            char* left = expr_copy;
            char* right = operator_pos + strlen(op) + 1;  // +1 for the space
            
            // Trim whitespace from operands
            while (*right && isspace(*right)) right++;
            char* end = left + strlen(left) - 1;
            while (end > left && isspace(*end)) {
                *end = '\0';
                end--;
            }
            
            // Get types of operands
            char* left_type = get_expression_type(left);
            char* right_type = get_expression_type(right);
            
            // Get result type
            char* result_type = get_result_type(op, left_type, right_type);
            
            free(expr_copy);
            if (left_type) free(left_type);
            if (right_type) free(right_type);
            return result_type;
        }
    }
    
    // Check if it's an array access (expression contains '[')
    char* bracket = strchr(expr, '[');
    if (bracket) {
        // Extract array name and index
        char* array_expr = strdup(expr);
        char* bracket_pos = strchr(array_expr, '[');
        if (!bracket_pos) {
            free(array_expr);
            return NULL;
        }
        *bracket_pos = '\0';
        
        // Trim whitespace from array name
        char* array_name = array_expr;
        while (*array_name && isspace(*array_name)) array_name++;
        char* end = array_name + strlen(array_name) - 1;
        while (end > array_name && isspace(*end)) {
            *end = '\0';
            end--;
        }
        
        // Handle collection member array access (e.g., "obj.member[idx]")
        char* dot = strchr(array_name, '.');
        if (dot) {
            *dot = '\0';
            Symbol* col_var = find_collection_var(array_name);
            if (col_var) {
                Collection* col_type = find_collection_type(col_var->type);
                if (col_type) {
                    char* member_name = dot + 1;
                    // Trim whitespace from member name
                    while (*member_name && isspace(*member_name)) member_name++;
                    end = member_name + strlen(member_name) - 1;
                    while (end > member_name && isspace(*end)) {
                        *end = '\0';
                        end--;
                    }
                    
                    for (Symbol* s = symbol_table; s != NULL; s = s->next) {
                        if (s->collection_name && strcmp(s->collection_name, col_type->name) == 0 && 
                            strcmp(s->name, member_name) == 0) {
                            char* base_type = strdup(s->type);
                            free(array_expr);
                            return base_type;
                        }
                    }
                }
            }
        } else {
            // Regular array access
            Symbol* sym = find_symbol(array_name);
            if (sym) {
                if (sym->is_array) {
                    char* base_type = strdup(sym->type);
                    free(array_expr);
                    return base_type;
                }
            }
        }
        free(array_expr);
        return NULL;
    }
    
    // Check if it's a float literal
    if (strchr(expr, '.')) {
        char* endptr;
        strtof(expr, &endptr);
        if (*endptr == '\0') {
            return strdup("float");
        }
    }
    
    // Check if it's an integer literal
    char* endptr;
    strtol(expr, &endptr, 10);
    if (*endptr == '\0') {
        return strdup("int");
    }
    
    // Check if it's an identifier
    Symbol* sym = find_symbol(expr);
    if (sym) {
        return strdup(sym->type);
    }
    
    // Check if it's a function call (expression contains parentheses)
    if (strchr(expr, '(')) {
        char* func_name = strdup(expr);
        char* paren = strchr(func_name, '(');
        if (!paren) {
            free(func_name);
            return NULL;
        }
        *paren = '\0';
        Function* func = find_function(func_name);
        free(func_name);
        if (func) {
            return strdup(func->return_type);
        }
    }
    
    return NULL;
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
%type <sval> assignment array_init member_assignments member_assignment
%type <sval> array_expression collection_expression function_expression collection_init
%type <sval> range_expression array_values_list

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
    : statement_list {
        // Check if main function exists
        Function* main_func = find_function("main");
        if (!main_func) {
            yyerror("Error: main function not defined");
            YYERROR;
        }
        // Check if main function has the correct return type (int)
        if (strcmp(main_func->return_type, "int") != 0) {
            yyerror("Error: main function must have int return type");
            YYERROR;
        }
        // Check if main function has no parameters
        if (main_func->params != NULL) {
            yyerror("Error: main function cannot have parameters");
            YYERROR;
        }
    }
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
    | RET expression ';'             { 
        if (current_function[0] == '\0') {
            yyerror("Return statement not allowed outside of function");
            YYERROR;
        }
        Function *func = find_function(current_function);
        if (!func) {
            char error[256];
            snprintf(error, sizeof(error), "Internal error: current function '%s' not found", current_function);
            yyerror(error);
            YYERROR;
        }
        if (strcmp(func->return_type, "void") == 0) {
            yyerror("Cannot return a value from a void function");
            YYERROR;
        }
        
        char* expr_type = get_expression_type($2);
               
        if (!are_types_compatible(func->return_type, expr_type)) {
            char error[256];
            snprintf(error, sizeof(error), 
                    "Type mismatch in return statement: cannot return '%s' from function returning '%s'",
                    expr_type ? expr_type : "unknown", func->return_type);
            if (expr_type) free(expr_type);
            yyerror(error);
            YYERROR;
        }
        if (expr_type) free(expr_type);
        
        print_scope_info("Return Statement", $2); 
        $$ = "return"; 
    }
    | RET ';'                        {
        if (current_function[0] == '\0') {
            yyerror("Return statement not allowed outside of function");
            YYERROR;
        }
        Function *func = find_function(current_function);
        if (!func) {
            char error[256];
            snprintf(error, sizeof(error), "Internal error: current function '%s' not found", current_function);
            yyerror(error);
            YYERROR;
        }
        if (strcmp(func->return_type, "void") != 0) {
            char error[256];
            snprintf(error, sizeof(error), 
                    "Type mismatch in return statement: function '%s' must return a value of type '%s'", 
                    current_function, func->return_type);
            yyerror(error);
            YYERROR;
        }
        print_scope_info("Return Statement", "void"); 
        $$ = "return"; 
    }
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
        add_symbol(d->name, d->type, 0, d->is_array, NULL, line_number, 0);
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
        add_symbol(d->name, d->type, 1, d->is_array, NULL, line_number, 0);
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
        add_symbol(d->name, d->type, 0, 1, NULL, line_number, 0);
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
        
        // Check value type
        char* value_type = get_expression_type($3);
        if (!are_types_compatible(d->type, value_type)) {
            char error[256];
            snprintf(error, sizeof(error), 
                    "Type mismatch in initialization: cannot assign '%s' to variable of type '%s'",
                    value_type ? value_type : "unknown", d->type);
            yyerror(error);
            free_declaration(d);
            YYERROR;
        }
        
        $$.name = d->name;
        $$.type = d->type;
        add_symbol(d->name, d->type, 0, d->is_array, $3, line_number, 0);
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
        
        // Check value type
        char* value_type = get_expression_type($3);
        if (!are_types_compatible(d->type, value_type)) {
            char error[256];
            snprintf(error, sizeof(error), 
                    "Type mismatch in initialization: cannot assign '%s' to constant of type '%s'",
                    value_type ? value_type : "unknown", d->type);
            yyerror(error);
            free_declaration(d);
            YYERROR;
        }
        
        $$.name = d->name;
        $$.type = d->type;
        add_symbol(d->name, d->type, 1, d->is_array, $3, line_number, 0);
        declarations++;
        assignments++;
        log_declaration("Constant", d->name, d->type, $3);
        free_declaration(d);
    }
    | ARRAY_DECL ASSIGN '[' array_values_list ']' {
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
            snprintf(error, sizeof(error), 
                    "Cannot initialize non-array variable '%s' with array values", d->name);
            yyerror(error);
            free_declaration(d);
            YYERROR;
        }
        $$.name = d->name;
        $$.type = d->type;
        add_symbol(d->name, d->type, 0, 1, "array initializer", line_number, 0);
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
        add_symbol(d->name, d->type, 0, d->is_array, NULL, line_number, 0);
        char info[256];
        sprintf(info, "Collection Member: %s of type %s", d->name, d->type);
        print_scope_info("Collection Member", info);
        free_declaration(d);
    }
    | ARRAY_DECL                   { 
        Declaration* d = extract_declaration($1, NULL, line_number);
        $$ = d->name;
        add_symbol(d->name, d->type, 0, 1, NULL, line_number, 0);
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
        current_function[sizeof(current_function)-1] = '\0';  // Ensure null termination
        print_scope_info("Function Start", $2);
        in_function_params = 1;  // Set when starting parameter list
    }
    '(' parameter_list ')' { 
        in_function_params = 0;  // Clear after parameter list
    } '>' type {
        // Add function to table before processing block
        add_function($2, $9);
        // Link parameters to function
        Function* func = find_function($2);
        if (func) {
            // Find all parameters for this function and link them
            for (Symbol* sym = symbol_table; sym != NULL; sym = sym->next) {
                if (sym->function_name && strcmp(sym->function_name, $2) == 0 && 
                    sym->is_temporary && sym->scope_level == scope_level) {
                    // Add parameter to function's parameter list
                    Symbol* param = malloc(sizeof(Symbol));
                    param->name = strdup(sym->name);
                    param->type = strdup(sym->type);
                    param->is_array = sym->is_array;
                    param->next = func->params;
                    func->params = param;
                }
            }
        }
    } block {
        print_scope_info("Function End", $2);
        current_function[0] = '\0';  // Clear function context
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
        add_symbol(d->name, d->type, 0, d->is_array, NULL, line_number, 1);  // Parameters are temporary
        char info[256];
        sprintf(info, "Parameter: %s of type %s", d->name, d->type);
        print_scope_info("Parameter", info);
        free_declaration(d);
    }
    | ARRAY_DECL                   { 
        Declaration* d = extract_declaration($1, NULL, line_number);
        $$ = d->name;
        add_symbol(d->name, d->type, 0, 1, NULL, line_number, 1);  // Parameters are temporary
        char info[256];
        sprintf(info, "Array Parameter: %s of type %s", d->name, d->type);
        print_scope_info("Array Parameter", info);
        free_declaration(d);
    }
    | CONST_DECL ASSIGN expression { 
        Declaration* d = extract_declaration($1, $3, line_number);
        $$ = d->name;
        add_symbol(d->name, d->type, 1, d->is_array, $3, line_number, 1);  // Parameters are temporary
        char info[256];
        sprintf(info, "Constant Parameter: %s of type %s = %s", d->name, d->type, $3);
        print_scope_info("Constant Parameter", info);
        free_declaration(d);
    }
    | CONST_DECL ASSIGN '[' array_values_list ']' {
        Declaration* d = extract_declaration($1, NULL, line_number);
        $$ = d->name;
        add_symbol(d->name, d->type, 1, 1, "array initializer", line_number, 1);  // Parameters are temporary
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
                YYERROR;
            } else if (sym->is_array) {
                yyerror("Cannot assign scalar value to array");
                YYERROR;
            } else {
                char* expr_type = get_expression_type($3);
                if (!are_types_compatible(sym->type, expr_type)) {
                    char error[256];
                    snprintf(error, sizeof(error), 
                            "Type mismatch in assignment: cannot assign '%s' to variable of type '%s'",
                            expr_type ? expr_type : "unknown", sym->type);
                    if (expr_type) free(expr_type);
                    yyerror(error);
                    YYERROR;
                }
                if (expr_type) free(expr_type);
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
            YYERROR;
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
                YYERROR;
            }
            
            // Check index type
            char* index_type = get_expression_type($3);
            if (!index_type || strcmp(index_type, "int") != 0) {
                char error[256];
                snprintf(error, sizeof(error), "Array index must be integer, got '%s'", 
                        index_type ? index_type : "unknown");
                if (index_type) free(index_type);
                yyerror(error);
                YYERROR;
            }
            if (index_type) free(index_type);
            
            // Check value type
            char* value_type = get_expression_type($6);
            if (!are_types_compatible(sym->type, value_type)) {
                char error[256];
                snprintf(error, sizeof(error), 
                        "Type mismatch in array assignment: cannot assign '%s' to array of type '%s'",
                        value_type ? value_type : "unknown", sym->type);
                if (value_type) free(value_type);
                yyerror(error);
                YYERROR;
            }
            if (value_type) free(value_type);
            
            assignments++;
            log_array_access($1, $3);
            log_assignment($1, $6, sym->type);
        } else {
            char error[256];
            snprintf(error, sizeof(error), "Undefined array '%s'", $1);
            yyerror(error);
            YYERROR;
        }
        $$ = "array_assignment";
    }
    | IDENTIFIER ASSIGN '[' array_values_list ']' {
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
        
        // Check each array value's type
        char* values_copy = strdup($4);
        char* value = strtok(values_copy, ",");
        while (value) {
            // Skip whitespace
            while (*value && isspace(*value)) value++;
            
            char* value_type = get_expression_type(value);
            if (!are_types_compatible(sym->type, value_type)) {
                char error[256];
                snprintf(error, sizeof(error), 
                        "Type mismatch in array initialization: cannot assign '%s' to array of type '%s'",
                        value_type ? value_type : "unknown", sym->type);
                if (value_type) free(value_type);
                free(values_copy);
                yyerror(error);
                YYERROR;
            }
            if (value_type) free(value_type);
            value = strtok(NULL, ",");
        }
        free(values_copy);
        
        assignments++;
        log_assignment($1, $4, sym->type);
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
                snprintf(error, sizeof(error), "Variable '%s' of type '%s' is not a collection", 
                        $1, var->type);
                yyerror(error);
            }
            YYERROR;
        }
        
        // Check if member exists in collection type
        Collection *col_type = find_collection_type(sym->type);
        Symbol *member = NULL;
        for (Symbol *s = symbol_table; s != NULL; s = s->next) {
            if (s->collection_name && strcmp(s->collection_name, col_type->name) == 0 && 
                strcmp(s->name, $3) == 0) {
                member = s;
                break;
            }
        }
        if (!member) {
            char error[256];
            snprintf(error, sizeof(error), "Member '%s' not found in collection type '%s'", 
                    $3, sym->type);
            yyerror(error);
            YYERROR;
        }
        
        // Check value type
        char* value_type = get_expression_type($5);
        if (!are_types_compatible(member->type, value_type)) {
            char error[256];
            snprintf(error, sizeof(error), 
                    "Type mismatch in member assignment: cannot assign '%s' to member of type '%s'",
                    value_type ? value_type : "unknown", member->type);
            if (value_type) free(value_type);
            yyerror(error);
            YYERROR;
        }
        if (value_type) free(value_type);
        
        assignments++;
        log_collection_access($1, $3);
        log_assignment($3, $5, member->type);
        $$ = "member_assignment";
    }
    | IDENTIFIER '.' IDENTIFIER ASSIGN array_init {
        Symbol *sym = find_collection_var($1);
        if (!sym) {
            Symbol *var = find_symbol($1);
            if (!var) {
                char error[256];
                snprintf(error, sizeof(error), "Undefined identifier '%s'", $1);
                yyerror(error);
            } else {
                char error[256];
                snprintf(error, sizeof(error), "Variable '%s' of type '%s' is not a collection", 
                        $1, var->type);
                yyerror(error);
            }
            YYERROR;
        }
        
        // Check if member exists in collection type
        Collection *col_type = find_collection_type(sym->type);
        Symbol *member = NULL;
        for (Symbol *s = symbol_table; s != NULL; s = s->next) {
            if (s->collection_name && strcmp(s->collection_name, col_type->name) == 0 && 
                strcmp(s->name, $3) == 0) {
                member = s;
                break;
            }
        }
        if (!member) {
            char error[256];
            snprintf(error, sizeof(error), "Member '%s' not found in collection type '%s'", 
                    $3, sym->type);
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
        $$ = "array_assignment";
    }
    | IDENTIFIER ASSIGN array_init {
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
        $$ = $1;
    }
    | IDENTIFIER ASSIGN array_init {
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
        $$ = $1;
    }
    ;

array_init
    : '[' array_values_list ']'    { $$ = $2; }
    | '[' ']'                      { $$ = ""; }  // Explicit empty array rule
    ;

array_values_list
    : expression                   { $$ = $1; }
    | array_values_list ',' expression { 
        char* result = malloc(strlen($1) + strlen($3) + 3);
        sprintf(result, "%s, %s", $1, $3);
        free($1);
        $$ = result;
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
    | LOOP VAR_DECL FOR range_expression { 
        // Case 1: Iterator declared in loop
        Declaration* d = extract_declaration($2, NULL, line_number);
        add_symbol(d->name, d->type, 0, d->is_array, NULL, line_number, 1);  // Loop iterators are temporary
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
        free($4);
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
        free($2);
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
    | STRING                      { $$ = strdup($1); }
    | array_expression            { $$ = strdup($1); }
    | collection_expression       { $$ = $1; }
    | function_expression         { $$ = strdup($1); }
    | '(' expression ')'          { 
                                   char* result = malloc(strlen($2) + 3);
                                   sprintf(result, "(%s)", $2);
                                   free($2);
                                   $$ = result;
                                 }
    | expression '+' expression   { 
                                   char* type1 = get_expression_type($1);
                                   char* type2 = get_expression_type($3);
                                   char* result_type = get_result_type("+", type1, type2);
                                   if (!result_type) {
                                       char error[256];
                                       snprintf(error, sizeof(error), 
                                              "Type mismatch in addition: cannot add '%s' and '%s'", 
                                              type1 ? type1 : "unknown", type2 ? type2 : "unknown");
                                       yyerror(error);
                                       YYERROR;
                                   }
                                   char* result = malloc(strlen($1) + strlen($3) + 4);
                                   sprintf(result, "%s + %s", $1, $3);
                                   log_operation("Addition", $1, $3, result);
                                   free($1);
                                   free($3);
                                   $$ = result;
                                 }
    | expression '-' expression   { 
                                   char* type1 = get_expression_type($1);
                                   char* type2 = get_expression_type($3);
                                   char* result_type = get_result_type("-", type1, type2);
                                   if (!result_type) {
                                       char error[256];
                                       snprintf(error, sizeof(error), 
                                              "Type mismatch in subtraction: cannot subtract '%s' from '%s'", 
                                              type2 ? type2 : "unknown", type1 ? type1 : "unknown");
                                       yyerror(error);
                                       YYERROR;
                                   }
                                   char* result = malloc(strlen($1) + strlen($3) + 4);
                                   sprintf(result, "%s - %s", $1, $3);
                                   log_operation("Subtraction", $1, $3, result);
                                   free($1);
                                   free($3);
                                   $$ = result;
                                 }
    | expression '*' expression   { 
                                   char* type1 = get_expression_type($1);
                                   char* type2 = get_expression_type($3);
                                   char* result_type = get_result_type("*", type1, type2);
                                   if (!result_type) {
                                       char error[256];
                                       snprintf(error, sizeof(error), 
                                              "Type mismatch in multiplication: cannot multiply '%s' and '%s'", 
                                              type1 ? type1 : "unknown", type2 ? type2 : "unknown");
                                       yyerror(error);
                                       YYERROR;
                                   }
                                   char* result = malloc(strlen($1) + strlen($3) + 4);
                                   sprintf(result, "%s * %s", $1, $3);
                                   log_operation("Multiplication", $1, $3, result);
                                   free($1);
                                   free($3);
                                   $$ = result;
                                 }
    | expression '/' expression   { 
                                   char* type1 = get_expression_type($1);
                                   char* type2 = get_expression_type($3);
                                   char* result_type = get_result_type("/", type1, type2);
                                   if (!result_type) {
                                       char error[256];
                                       snprintf(error, sizeof(error), 
                                              "Type mismatch in division: cannot divide '%s' by '%s'", 
                                              type1 ? type1 : "unknown", type2 ? type2 : "unknown");
                                       yyerror(error);
                                       YYERROR;
                                   }
                                   char* result = malloc(strlen($1) + strlen($3) + 4);
                                   sprintf(result, "%s / %s", $1, $3);
                                   log_operation("Division", $1, $3, result);
                                   free($1);
                                   free($3);
                                   $$ = result;
                                 }
    | expression '%' expression   { 
                                   char* type1 = get_expression_type($1);
                                   char* type2 = get_expression_type($3);
                                   char* result_type = get_result_type("%", type1, type2);
                                   if (!result_type) {
                                       char error[256];
                                       snprintf(error, sizeof(error), 
                                              "Type mismatch in modulo: operands must be integers, got '%s' and '%s'", 
                                              type1 ? type1 : "unknown", type2 ? type2 : "unknown");
                                       yyerror(error);
                                       YYERROR;
                                   }
                                   char* result = malloc(strlen($1) + strlen($3) + 4);
                                   sprintf(result, "%s %% %s", $1, $3);
                                   log_operation("Modulo", $1, $3, result);
                                   free($1);
                                   free($3);
                                   $$ = result;
                                 }
    | expression '&' expression   { 
                                   char* type1 = get_expression_type($1);
                                   char* type2 = get_expression_type($3);
                                   char* result_type = get_result_type("&", type1, type2);
                                   if (!result_type) {
                                       char error[256];
                                       snprintf(error, sizeof(error), 
                                              "Type mismatch in bitwise AND: operands must be integers, got '%s' and '%s'", 
                                              type1 ? type1 : "unknown", type2 ? type2 : "unknown");
                                       yyerror(error);
                                       YYERROR;
                                   }
                                   char* result = malloc(strlen($1) + strlen($3) + 4);
                                   sprintf(result, "%s & %s", $1, $3);
                                   log_operation("Bitwise AND", $1, $3, result);
                                   free($1);
                                   free($3);
                                   $$ = result;
                                 }
    | expression '|' expression   { 
                                   char* type1 = get_expression_type($1);
                                   char* type2 = get_expression_type($3);
                                   char* result_type = get_result_type("|", type1, type2);
                                   if (!result_type) {
                                       char error[256];
                                       snprintf(error, sizeof(error), 
                                              "Type mismatch in bitwise OR: operands must be integers, got '%s' and '%s'", 
                                              type1 ? type1 : "unknown", type2 ? type2 : "unknown");
                                       yyerror(error);
                                       YYERROR;
                                   }
                                   char* result = malloc(strlen($1) + strlen($3) + 4);
                                   sprintf(result, "%s | %s", $1, $3);
                                   log_operation("Bitwise OR", $1, $3, result);
                                   free($1);
                                   free($3);
                                   $$ = result;
                                 }
    | expression '^' expression   { 
                                   char* type1 = get_expression_type($1);
                                   char* type2 = get_expression_type($3);
                                   char* result_type = get_result_type("^", type1, type2);
                                   if (!result_type) {
                                       char error[256];
                                       snprintf(error, sizeof(error), 
                                              "Type mismatch in bitwise XOR: operands must be integers, got '%s' and '%s'", 
                                              type1 ? type1 : "unknown", type2 ? type2 : "unknown");
                                       yyerror(error);
                                       YYERROR;
                                   }
                                   char* result = malloc(strlen($1) + strlen($3) + 4);
                                   sprintf(result, "%s ^ %s", $1, $3);
                                   log_operation("Bitwise XOR", $1, $3, result);
                                   free($1);
                                   free($3);
                                   $$ = result;
                                 }
    | '~' expression             { 
                                   char* type = get_expression_type($2);
                                   if (!type || strcmp(type, "int") != 0) {
                                       char error[256];
                                       snprintf(error, sizeof(error), 
                                              "Type mismatch in bitwise NOT: operand must be integer, got '%s'", 
                                              type ? type : "unknown");
                                       yyerror(error);
                                       YYERROR;
                                   }
                                   char* result = malloc(strlen($2) + 2);
                                   sprintf(result, "~%s", $2);
                                   log_operation("Bitwise NOT", $2, "", result);
                                   free($2);
                                   $$ = result;
                                 }
    | expression EQ expression    { 
                                   char* type1 = get_expression_type($1);
                                   char* type2 = get_expression_type($3);
                                   char* result_type = get_result_type("==", type1, type2);
                                   if (!result_type) {
                                       char error[256];
                                       snprintf(error, sizeof(error), 
                                              "Type mismatch in equality comparison: cannot compare '%s' and '%s'", 
                                              type1 ? type1 : "unknown", type2 ? type2 : "unknown");
                                       yyerror(error);
                                       YYERROR;
                                   }
                                   char* result = malloc(strlen($1) + strlen($3) + 5);
                                   sprintf(result, "%s == %s", $1, $3);
                                   log_operation("Equals", $1, $3, result);
                                   free($1);
                                   free($3);
                                   $$ = result;
                                 }
    | expression LT expression    { 
                                   char* type1 = get_expression_type($1);
                                   char* type2 = get_expression_type($3);
                                   char* result_type = get_result_type("<", type1, type2);
                                   if (!result_type) {
                                       char error[256];
                                       snprintf(error, sizeof(error), 
                                              "Type mismatch in less than comparison: cannot compare '%s' and '%s'", 
                                              type1 ? type1 : "unknown", type2 ? type2 : "unknown");
                                       yyerror(error);
                                       YYERROR;
                                   }
                                   char* result = malloc(strlen($1) + strlen($3) + 4);
                                   sprintf(result, "%s < %s", $1, $3);
                                   log_operation("Less Than", $1, $3, result);
                                   free($1);
                                   free($3);
                                   $$ = result;
                                 }
    | expression GT expression    { 
                                   char* type1 = get_expression_type($1);
                                   char* type2 = get_expression_type($3);
                                   char* result_type = get_result_type(">", type1, type2);
                                   if (!result_type) {
                                       char error[256];
                                       snprintf(error, sizeof(error), 
                                              "Type mismatch in greater than comparison: cannot compare '%s' and '%s'", 
                                              type1 ? type1 : "unknown", type2 ? type2 : "unknown");
                                       yyerror(error);
                                       YYERROR;
                                   }
                                   char* result = malloc(strlen($1) + strlen($3) + 4);
                                   sprintf(result, "%s > %s", $1, $3);
                                   log_operation("Greater Than", $1, $3, result);
                                   free($1);
                                   free($3);
                                   $$ = result;
                                 }
    | expression LE expression    { 
                                   char* type1 = get_expression_type($1);
                                   char* type2 = get_expression_type($3);
                                   char* result_type = get_result_type("<=", type1, type2);
                                   if (!result_type) {
                                       char error[256];
                                       snprintf(error, sizeof(error), 
                                              "Type mismatch in less than or equal comparison: cannot compare '%s' and '%s'", 
                                              type1 ? type1 : "unknown", type2 ? type2 : "unknown");
                                       yyerror(error);
                                       YYERROR;
                                   }
                                   char* result = malloc(strlen($1) + strlen($3) + 5);
                                   sprintf(result, "%s <= %s", $1, $3);
                                   log_operation("Less Equal", $1, $3, result);
                                   free($1);
                                   free($3);
                                   $$ = result;
                                 }
    | expression GE expression    { 
                                   char* type1 = get_expression_type($1);
                                   char* type2 = get_expression_type($3);
                                   char* result_type = get_result_type(">=", type1, type2);
                                   if (!result_type) {
                                       char error[256];
                                       snprintf(error, sizeof(error), 
                                              "Type mismatch in greater than or equal comparison: cannot compare '%s' and '%s'", 
                                              type1 ? type1 : "unknown", type2 ? type2 : "unknown");
                                       yyerror(error);
                                       YYERROR;
                                   }
                                   char* result = malloc(strlen($1) + strlen($3) + 5);
                                   sprintf(result, "%s >= %s", $1, $3);
                                   log_operation("Greater Equal", $1, $3, result);
                                   free($1);
                                   free($3);
                                   $$ = result;
                                 }
    | expression AND expression   { 
                                   char* type1 = get_expression_type($1);
                                   char* type2 = get_expression_type($3);
                                   char* result_type = get_result_type("&&", type1, type2);
                                   if (!result_type) {
                                       char error[256];
                                       snprintf(error, sizeof(error), 
                                              "Type mismatch in logical AND: operands must be boolean, got '%s' and '%s'", 
                                              type1 ? type1 : "unknown", type2 ? type2 : "unknown");
                                       yyerror(error);
                                       YYERROR;
                                   }
                                   char* result = malloc(strlen($1) + strlen($3) + 5);
                                   sprintf(result, "%s && %s", $1, $3);
                                   log_operation("Logical AND", $1, $3, result);
                                   free($1);
                                   free($3);
                                   $$ = result;
                                 }
    | expression OR expression    { 
                                   char* type1 = get_expression_type($1);
                                   char* type2 = get_expression_type($3);
                                   char* result_type = get_result_type("||", type1, type2);
                                   if (!result_type) {
                                       char error[256];
                                       snprintf(error, sizeof(error), 
                                              "Type mismatch in logical OR: operands must be boolean, got '%s' and '%s'", 
                                              type1 ? type1 : "unknown", type2 ? type2 : "unknown");
                                       yyerror(error);
                                       YYERROR;
                                   }
                                   char* result = malloc(strlen($1) + strlen($3) + 5);
                                   sprintf(result, "%s || %s", $1, $3);
                                   log_operation("Logical OR", $1, $3, result);
                                   free($1);
                                   free($3);
                                   $$ = result;
                                 }
    | NOT expression             { 
                                   char* type = get_expression_type($2);
                                   if (!type || strcmp(type, "bool") != 0) {
                                       char error[256];
                                       snprintf(error, sizeof(error), 
                                              "Type mismatch in logical NOT: operand must be boolean, got '%s'", 
                                              type ? type : "unknown");
                                       yyerror(error);
                                       YYERROR;
                                   }
                                   char* result = malloc(strlen($2) + 2);
                                   sprintf(result, "!%s", $2);
                                   log_operation("Logical NOT", $2, "", result);
                                   free($2);
                                   $$ = result;
                                 }
    | '-' expression %prec UMINUS { 
                                   char* type = get_expression_type($2);
                                   if (!type || (strcmp(type, "int") != 0 && strcmp(type, "float") != 0)) {
                                       char error[256];
                                       snprintf(error, sizeof(error), 
                                              "Type mismatch in unary minus: operand must be numeric, got '%s'", 
                                              type ? type : "unknown");
                                       yyerror(error);
                                       YYERROR;
                                   }
                                   char* result = malloc(strlen($2) + 2);
                                   sprintf(result, "-%s", $2);
                                   log_operation("Negation", $2, "", result);
                                   free($2);
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
                                   $$ = strdup($1);
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
        
        // Check index type
        char* index_type = get_expression_type($3);
        if (!index_type || strcmp(index_type, "int") != 0) {
            char error[256];
            snprintf(error, sizeof(error), "Array index must be integer, got '%s'", 
                    index_type ? index_type : "unknown");
            yyerror(error);
            YYERROR;
        }
        
        // Create array access expression with brackets
        char* result = malloc(strlen($1) + strlen($3) + 4); // +4 for '[', ']', and '\0'
        sprintf(result, "%s[%s]", $1, $3);
        log_array_access($1, $3);
        $$ = result;
    }
    | collection_expression '[' expression ']' {
        // Handle array access on collection members
        if (!strstr($1, ".")) {
            char error[256];
            snprintf(error, sizeof(error), "Invalid array access on non-member expression");
            yyerror(error);
            YYERROR;
        }
        
        // Extract collection and member names
        char* expr_copy = strdup($1);
        char* dot = strchr(expr_copy, '.');
        if (!dot) {
            free(expr_copy);
            yyerror("Invalid collection member access");
            YYERROR;
        }
        *dot = '\0';
        char* member_name = dot + 1;
        
        // Verify collection and member
        Symbol* col_var = find_collection_var(expr_copy);
        if (!col_var) {
            char error[256];
            snprintf(error, sizeof(error), "Undefined collection variable '%s'", expr_copy);
            free(expr_copy);
            yyerror(error);
            YYERROR;
        }
        
        Collection* col_type = find_collection_type(col_var->type);
        if (!col_type) {
            char error[256];
            snprintf(error, sizeof(error), "Invalid collection type for '%s'", expr_copy);
            free(expr_copy);
            yyerror(error);
            YYERROR;
        }
        
        Symbol* member = NULL;
        for (Symbol* s = symbol_table; s != NULL; s = s->next) {
            if (s->collection_name && strcmp(s->collection_name, col_type->name) == 0 && 
                strcmp(s->name, member_name) == 0) {
                member = s;
                break;
            }
        }
        
        if (!member || !member->is_array) {
            char error[256];
            snprintf(error, sizeof(error), "Member '%s' is not an array", member_name);
            free(expr_copy);
            yyerror(error);
            YYERROR;
        }
        
        // Check index type
        char* index_type = get_expression_type($3);
        if (!index_type || strcmp(index_type, "int") != 0) {
            char error[256];
            snprintf(error, sizeof(error), "Array index must be integer, got '%s'", 
                    index_type ? index_type : "unknown");
            free(expr_copy);
            yyerror(error);
            YYERROR;
        }
        
        // Create array access expression with brackets
        char* result = malloc(strlen($1) + strlen($3) + 4); // +4 for '[', ']', and '\0'
        sprintf(result, "%s[%s]", $1, $3);
        log_array_access($1, $3);
        free(expr_copy);
        $$ = result;
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
                snprintf(error, sizeof(error), "Variable '%s' of type '%s' is not a collection", 
                        $1, var->type);
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
        
        // Count arguments
        int arg_count = 0;
        if (strlen($3) > 0) {  // If argument list is not empty
            arg_count = 1;  // Start with 1 for the first argument
            for (char* p = $3; *p; p++) {
                if (*p == ',') arg_count++;  // Count commas for additional arguments
            }
        }
        
        // Count parameters
        int param_count = 0;
        for (Symbol* param = func->params; param != NULL; param = param->next) {
            param_count++;
        }
        
        if (arg_count != param_count) {
            char error[256];
            if (arg_count < param_count) {
                snprintf(error, sizeof(error), "Too few arguments in call to function '%s'", $1);
            } else {
                snprintf(error, sizeof(error), "Too many arguments in call to function '%s'", $1);
            }
            yyerror(error);
            YYERROR;
        }
        
        // Check argument types
        Symbol *param = func->params;
        char *arg_list = strdup($3);
        char *arg = strtok(arg_list, ",");
        
        while (param && arg) {
            // Skip whitespace
            while (*arg && isspace(*arg)) arg++;
            
            // Check if argument is a collection member array access
            char* dot = strchr(arg, '.');
            if (dot) {
                char* expr_copy = strdup(arg);
                char* dot_pos = strchr(expr_copy, '.');
                *dot_pos = '\0';
                char* col_name = expr_copy;
                char* member_name = dot_pos + 1;
                
                Symbol* col_var = find_collection_var(col_name);
                if (col_var) {
                    Collection* col_type = find_collection_type(col_var->type);
                    if (col_type) {
                        for (Symbol* s = symbol_table; s != NULL; s = s->next) {
                            if (s->collection_name && strcmp(s->collection_name, col_type->name) == 0 && 
                                strcmp(s->name, member_name) == 0) {
                                if (s->is_array != param->is_array) {
                                    char error[256];
                                    snprintf(error, sizeof(error), 
                                          "Type mismatch in function call: argument '%s' array type mismatch with parameter '%s'",
                                          arg, param->name);
                                    free(expr_copy);
                                    free(arg_list);
                                    yyerror(error);
                                    YYERROR;
                                }
                                
                                if (!are_types_compatible(param->type, s->type)) {
                                    char error[256];
                                    snprintf(error, sizeof(error), 
                                            "Type mismatch in function call: argument '%s' of type '%s' cannot be passed to parameter '%s' of type '%s'",
                                            arg, s->type, param->name, param->type);
                                    free(expr_copy);
                                    free(arg_list);
                                    yyerror(error);
                                    YYERROR;
                                }
                                free(expr_copy);
                                break;
                            }
                        }
                    }
                }
                free(expr_copy);
            } else {
                // Regular argument type check
                char* arg_type = get_expression_type(arg);
                
                if (!are_types_compatible(param->type, arg_type)) {
                    char error[256];
                    snprintf(error, sizeof(error), 
                            "Type mismatch in function call: argument '%s' of type '%s' cannot be passed to parameter '%s' of type '%s'",
                            arg, arg_type ? arg_type : "unknown", param->name, param->type);
                    if (arg_type) free(arg_type);
                    free(arg_list);
                    yyerror(error);
                    YYERROR;
                }
                if (arg_type) free(arg_type);
            }
            
            param = param->next;
            arg = strtok(NULL, ",");
        }
        
        free(arg_list);
        function_calls++;
        log_function_call($1, arg_count);
        
        // Create function call expression
        char* result = malloc(strlen($1) + strlen($3) + 4);
        sprintf(result, "%s(%s)", $1, $3);
        $$ = result;
    }
    ;

argument_list
    : /* empty */                  { $$ = ""; }
    | expression                   { $$ = $1; }
    | argument_list ',' expression { 
        char* result = malloc(strlen($1) + strlen($3) + 3);
        sprintf(result, "%s, %s", $1, $3);
        free($1);
        $$ = result;
    }
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

    // Open output file
    output_file = fopen("output.txt", "w");
    if (!output_file) {
        fprintf(stderr, "Error: Cannot create output file 'output.txt'\n");
        fclose(input);
        return 1;
    }

    yyin = input;

    fprintf(output_file, "Parsing file: %s\n\n", argv[1]);
    int result = yyparse();
    
    fprintf(output_file, "\n=== Compilation Statistics ===\n");
    fprintf(output_file, "Declarations: %d\n", declarations);
    fprintf(output_file, "Assignments: %d\n", assignments);
    fprintf(output_file, "Function Calls: %d\n", function_calls);
    fprintf(output_file, "Conditions: %d\n", conditions);
    fprintf(output_file, "Loops: %d\n", loops);
    
    fclose(input);
    fclose(output_file);
    return result;
}

void yyerror(const char *s) {
    fprintf(output_file, "Error at line %d: %s\n", line_number, s);
    fprintf(output_file, "Near token: '%s'\n", yytext);
}

void print_scope_info(const char *action, const char *details) {
    char indent[256] = "";
    for (int i = 0; i < scope_level; i++) {
        strcat(indent, "  ");
    }
    
    char context[512] = "";
    
    fprintf(output_file, "Line %-5d%s: %s%s: %s\n", line_number, context, indent, action, details);
}

void enter_scope(void) {
    scope_level++;
}

void exit_scope(void) {
    if (scope_level > 0) {
        cleanup_temporary_symbols(scope_level);
        scope_level--;
    }
}

void cleanup_temporary_symbols(int scope) {
    Symbol *prev = NULL;
    Symbol *current = symbol_table;
    
    while (current != NULL) {
        if (current->scope_level == scope && current->is_temporary) {
            Symbol *to_delete = current;
            if (prev) {
                prev->next = current->next;
                current = current->next;
            } else {
                symbol_table = current->next;
                current = symbol_table;
            }
            free(to_delete->name);
            free(to_delete->type);
            if (to_delete->value) free(to_delete->value);
            if (to_delete->function_name) free(to_delete->function_name);
            if (to_delete->collection_name) free(to_delete->collection_name);
            free(to_delete);
        } else {
            prev = current;
            current = current->next;
        }
    }
}

void add_symbol(const char *name, const char *type, int is_const, int is_array, const char *value, int line_num, int is_temporary) {
    // Check if name is a reserved keyword
    if (!validate_identifier(name, "variable")) {
        return;
    }
    
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
            if (sym->scope_level == scope_level && 
                strcmp(sym->name, name) == 0 && 
                !sym->collection_name) {
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
    sym->is_const = is_const;
    sym->is_array = is_array;
    sym->is_temporary = is_temporary;  // Set temporary flag
    sym->line_num = line_num;
    sym->scope_level = scope_level;
    sym->function_name = current_function[0] ? strdup(current_function) : NULL;
    sym->collection_name = current_collection[0] ? strdup(current_collection) : NULL;
    sym->next = symbol_table;
    symbol_table = sym;

    declarations++;

    const char* kind = is_const ? "Constant" : 
                      is_array ? "Array" :
                      in_function_params ? "Parameter" :
                      current_collection[0] ? "Member" : "Variable";
    log_declaration(kind, name, type, value);
}

void add_function(const char *name, const char *return_type) {
    // Check if name is a reserved keyword
    if (!validate_identifier(name, "function")) {
        return;
    }

    if(find_collection(name)) {
        char error[256];
        snprintf(error, sizeof(error), "Name '%s' is already used as a collection", name);
        yyerror(error);
        return;
    }

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
    // Check if name is a reserved keyword
    if (!validate_identifier(name, "collection")) {
        return;
    }

    if(find_function(name)) {
        char error[256];
        snprintf(error, sizeof(error), "Name '%s' is already used as a function", name);
        yyerror(error);
        return;
    }

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

void log_declaration(const char *kind, const char *name, const char *type, const char *value) {
    char indent[256] = "";
    for (int i = 0; i < scope_level; i++) {
        strcat(indent, "  ");
    }
    
    char context[512] = "";
    
    if (value) {
        fprintf(output_file, "Line %-5d%s: %s%s Declaration: %s of type %s = %s\n", 
               line_number, context, indent, kind, name, type, value);
    } else {
        fprintf(output_file, "Line %-5d%s: %s%s Declaration: %s of type %s\n", 
               line_number, context, indent, kind, name, type);
    }
}

void log_assignment(const char *target, const char *value, const char *type) {
    char indent[256] = "";
    for (int i = 0; i < scope_level; i++) {
        strcat(indent, "  ");
    }
    
    char context[512] = "";
    
    fprintf(output_file, "Line %-5d%s: %sAssignment: %s = %s (type: %s)\n", 
           line_number, context, indent, target, value, type);
}

void log_operation(const char *op, const char *left, const char *right, const char *result) {
    char indent[256] = "";
    for (int i = 0; i < scope_level; i++) {
        strcat(indent, "  ");
    }
    
    char context[512] = "";
    
    if (right[0] != '\0') {
        fprintf(output_file, "Line %-5d%s: %sOperation: %s (%s, %s) = %s\n", 
               line_number, context, indent, op, left, right, result);
    } else {
        fprintf(output_file, "Line %-5d%s: %sOperation: %s (%s) = %s\n", 
               line_number, context, indent, op, left, result);
    }
}

void log_function_call(const char *name, int arg_count) {
    char indent[256] = "";
    for (int i = 0; i < scope_level; i++) {
        strcat(indent, "  ");
    }
    
    fprintf(output_file, "Line %-5d: %sFunction Call: %s with %d argument(s)\n", 
           line_number, indent, name, arg_count);
}

void log_condition(const char *type, const char *condition) {
    char indent[256] = "";
    for (int i = 0; i < scope_level; i++) {
        strcat(indent, "  ");
    }
    
    if (condition[0] != '\0') {
        fprintf(output_file, "Line %-5d: %s%s Condition: %s\n", 
               line_number, indent, type, condition);
    } else {
        fprintf(output_file, "Line %-5d: %s%s Branch\n", 
               line_number, indent, type);
    }
}

void log_loop(const char *type, const char *condition) {
    char indent[256] = "";
    for (int i = 0; i < scope_level; i++) {
        strcat(indent, "  ");
    }
    
    fprintf(output_file, "Line %-5d: %s%s: %s\n", 
           line_number, indent, type, condition);
}

void log_collection_access(const char *collection, const char *member) {
    char indent[256] = "";
    for (int i = 0; i < scope_level; i++) {
        strcat(indent, "  ");
    }
    
    fprintf(output_file, "Line %-5d: %sCollection Access: %s.%s\n", 
           line_number, indent, collection, member);
}

void log_array_access(const char *array, const char *index) {
    char indent[256] = "";
    for (int i = 0; i < scope_level; i++) {
        strcat(indent, "  ");
    }
    
    fprintf(output_file, "Line %-5d: %sArray Access: %s[%s]\n", 
           line_number, indent, array, index);
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
        fprintf(output_file, "Line %-5d%s: %s%s: %s\n", 
               line_number, context, indent, type, value);
    } else {
        fprintf(output_file, "Line %-5d%s: %s%s\n", 
               line_number, context, indent, type);
    }
}