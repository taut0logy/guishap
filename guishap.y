%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

// External declarations for lexer variables
extern int line_num;
extern int char_num;
extern char *yytext;
extern int yyleng;
extern int yychar;

// Token name lookup table
const char* token_names[] = {
    "COLLECTION_START",
    "NEWLINE",
    "EMPTY_LINE",
    "ASSIGN_OP",
    "MEMBER_ACCESS",
    "INTEGER",
    "FLOAT",
    "STRING_LITERAL",
    "IDENTIFIER",
    "CONSTANT_DECLARATION",
    "VARIABLE_DECLARATION",
    "ARRAY_IDENTIFIER",
    "ARRAY_DECLARATION",
    "FUNCTION",
    "FUNCTION_DEF",
    "RETURN_TYPE",
    "LOOP_TILL",
    "LOOP_FOR",
    "BREAK",
    "CONTINUE",
    "RETURN",
    "IF",
    "ELIF",
    "ELSE",
    "CASE",
    "BLOCK_COMMENT",
    "LINE_COMMENT",
    "SEMICOLON",
    "ARITHMETIC_OP_PLUS",
    "ARITHMETIC_OP_MINUS",
    "ARITHMETIC_OP_MULT",
    "ARITHMETIC_OP_DIV",
    "BITWISE_OP_AND",
    "BITWISE_OP_OR",
    "BITWISE_OP_NOT",
    "BITWISE_OP_XOR",
    "CONDITIONAL_OP_EQ",
    "CONDITIONAL_OP_LT",
    "CONDITIONAL_OP_GT",
    "CONDITIONAL_OP_LE",
    "CONDITIONAL_OP_GE",
    "LOGICAL_OP_AND",
    "LOGICAL_OP_OR",
    "LOGICAL_OP_NOT"
};

// Non-terminal name lookup table
const char* nonterminal_names[] = {
    "statement",
    "statement_list",
    "if_statement",
    "block",
    "case_statement",
    "case_block",
    "expression",
    "expr_arithmetic",
    "expr_bitwise",
    "expr_conditional",
    "expr_logical",
    "primary_expression",
    "function_statement",
    "assignment",
    "loop_statement",
    "program",
    "collection_member",
    "collection_members",
    "declaration",
    "members_with_newlines",
    "ws_or_newlines",
    "collection_declaration",
    "case_list",
    "case_item",
    "parameter_list",
    "parameter_declarations"
};

// Function to get token name
const char* get_token_name(int token) {
    if (token < 128) {  // ASCII characters
        static char single_char[2];
        single_char[0] = (char)token;
        single_char[1] = '\0';
        return single_char;
    }
    
    // Adjust token to index into token_names array
    int index = token - 258;  // 258 is the start of token values in bison
    if (index >= 0 && index < sizeof(token_names)/sizeof(token_names[0])) {
        return token_names[index];
    }
    return "UNKNOWN_TOKEN";
}

// Function to get non-terminal name
const char* get_nonterminal_name(int nonterminal) {
    if (nonterminal >= 0 && nonterminal < sizeof(nonterminal_names)/sizeof(nonterminal_names[0])) {
        return nonterminal_names[nonterminal];
    }
    return "UNKNOWN_NONTERMINAL";
}

void yyerror(const char *s) {
    fprintf(stderr, "Error at line %d, character %d: %s\n", line_num, char_num - yyleng, s);
    fprintf(stderr, "Near token: '%s'\n", yytext);
    
    // Print token name
    fprintf(stderr, "Terminal/Non-terminal: %s\n", get_token_name(yychar));
    
    // Print token type information
    if (strstr(yytext, "__%") != NULL) {
        fprintf(stderr, "Token type: Constant Declaration\n");
    } else if (strstr(yytext, "_%") != NULL && strstr(yytext, "[]") != NULL) {
        fprintf(stderr, "Token type: Array Declaration\n");
    } else if (strstr(yytext, "_%") != NULL) {
        fprintf(stderr, "Token type: Variable Declaration\n");
    } else if (strstr(yytext, "shap") != NULL) {
        fprintf(stderr, "Token type: Function Definition\n");
    } else if (strstr(yytext, "col") != NULL) {
        fprintf(stderr, "Token type: Collection Definition\n");
    } else if (strstr(yytext, "loop") != NULL) {
        fprintf(stderr, "Token type: Loop Statement\n");
    } else if (strstr(yytext, "if") != NULL || strstr(yytext, "elif") != NULL || strstr(yytext, "else") != NULL) {
        fprintf(stderr, "Token type: Conditional Statement\n");
    } else if (strstr(yytext, "case") != NULL) {
        fprintf(stderr, "Token type: Case Statement\n");
    } else if (isdigit(yytext[0]) || (yytext[0] == '-' && isdigit(yytext[1]))) {
        if (strchr(yytext, '.') != NULL) {
            fprintf(stderr, "Token type: Float Literal\n");
        } else {
            fprintf(stderr, "Token type: Integer Literal\n");
        }
    } else if (yytext[0] == '"') {
        fprintf(stderr, "Token type: String Literal\n");
    } else if (isalpha(yytext[0]) || yytext[0] == '_') {
        fprintf(stderr, "Token type: Identifier\n");
    } else {
        fprintf(stderr, "Token type: Operator/Symbol\n");
    }

}

int yylex(void);




// Add external declarations for variables from lexer
extern int line_comments;
extern int block_comments;
extern int declarations;
extern int functions;
extern int collections;
extern int arrays;
extern int identifiers;
extern int keywords;
extern int operators;
extern int loops;
extern int conditions;
extern int semicolons;

// Add position tracking variables
int prev_line_num = 1;
int prev_char_num = 0;

// Function to update position
void update_position() {
    prev_line_num = line_num;
    prev_char_num = char_num;
}

// Add this function to track token position
void update_token_pos() {
    prev_line_num = line_num;
    prev_char_num = char_num - yyleng;  // Start position of current token
}

typedef struct Symbol {
    char *name;
    char *data_type;
    char *value;
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

// Add counters for operations
int function_calls = 0;
int initializations = 0;
int assignments = 0;
int arithmetic_ops = 0;
int bitwise_ops = 0;
int logical_ops = 0;
int conditional_ops = 0;

// Add helper function for type checking
char* get_variable_type(const char* var_decl) {
    char* type_start = strchr(var_decl, '%');
    if (!type_start) return NULL;
    return type_start + 1;
}

// Add helper function for array type checking
char* get_array_base_type(const char* var_decl) {
    char* type_start = strchr(var_decl, '%');
    if (!type_start) return NULL;
    
    // Create a copy of the type portion
    char* type = strdup(type_start + 1);
    
    // Remove the [] suffix if present
    char* array_suffix = strstr(type, "[]");
    if (array_suffix) {
        *array_suffix = '\0';
    }
    
    return type;
}

// Add function to get type string from value
char* get_type_string(const char* value) {
    if (!value || value[0] == '\0') return NULL;
    
    // Check if it's a string literal (starts and ends with quotes)
    if (value[0] == '"') {
        int len = strlen(value);
        if (len >= 2 && value[len-1] == '"') {
            return "string";
        }
        return NULL;  // Invalid string literal
    }
    
    // Check if it's a float (contains a decimal point)
    if (strchr(value, '.') != NULL) {
        // Verify it's a valid float
        char* endptr;
        strtof(value, &endptr);
        if (*endptr == '\0') return "float";
        return NULL;
    }
    
    // Try to parse as int
    char* endptr;
    strtol(value, &endptr, 10);
    if (*endptr == '\0') return "int";
    
    return NULL;
}

// Modify type compatibility check to handle string literals properly
int check_type_compatibility(const char* var_type, const char* value_type) {
    if (!var_type || !value_type) return 0;
    
    // Check if either type is an array
    int var_is_array = strstr(var_type, "[]") != NULL;
    int val_is_array = strstr(value_type, "[]") != NULL;
    
    if (var_is_array != val_is_array) return 0;  // One is array, other is not
    
    if (var_is_array) {
        // Compare base types for arrays
        char* var_base = get_array_base_type(var_type);
        char* val_base = get_array_base_type(value_type);
        int result = check_type_compatibility(var_base, val_base);  // Recursive check for base types
        free(var_base);
        free(val_base);
        return result;
    }
    
    // Direct type match
    if (strcmp(var_type, value_type) == 0) return 1;
    
    // Allow numeric type conversions (both int to float and float to int)
    if ((strcmp(var_type, "float") == 0 && strcmp(value_type, "int") == 0) ||
        (strcmp(var_type, "int") == 0 && strcmp(value_type, "float") == 0)) {
        return 1;
    }
    
    return 0;
}

// Add this function to store numeric values in symbol table
void add_symbol_with_value(char *name, char *data_type, char *value) {
    Symbol *sym = (Symbol *)malloc(sizeof(Symbol));
    sym->name = strdup(name);
    sym->data_type = strdup(data_type);
    sym->value = strdup(value);
    sym->defined = 0;
    sym->next = symbol_table;
    symbol_table = sym;
}

%}

// Add new tokens
%token <stringValue> COLLECTION_START
%token NEWLINE EMPTY_LINE
%token ASSIGN_OP
%token MEMBER_ACCESS

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

%token <intValue> INTEGER
%token <floatValue> FLOAT
%token <stringValue> STRING_LITERAL IDENTIFIER
%token <stringValue> CONSTANT_DECLARATION VARIABLE_DECLARATION ARRAY_IDENTIFIER
%token <stringValue> FUNCTION
%token LOOP_TILL LOOP_FOR BREAK CONTINUE RETURN IF ELIF ELSE CASE 
%token BLOCK_COMMENT LINE_COMMENT SEMICOLON

%token <stringValue> ARITHMETIC_OP_PLUS ARITHMETIC_OP_MINUS ARITHMETIC_OP_MULT ARITHMETIC_OP_DIV
%token <stringValue> BITWISE_OP_AND BITWISE_OP_OR BITWISE_OP_NOT BITWISE_OP_XOR
%token <stringValue> CONDITIONAL_OP_EQ CONDITIONAL_OP_LT CONDITIONAL_OP_GT CONDITIONAL_OP_LE CONDITIONAL_OP_GE
%token <stringValue> LOGICAL_OP_AND LOGICAL_OP_OR LOGICAL_OP_NOT

%type <stringValue> statement statement_list
%type <stringValue> if_statement block case_statement case_block
%type <stringValue> expression expr_arithmetic expr_bitwise expr_conditional expr_logical
%type <stringValue> primary_expression
%type <function> function_statement
%type <stringValue> assignment loop_statement
%type <stringValue> program
%type <declaration> collection_member collection_members declaration
%type <declaration> members_with_newlines
%type <stringValue> ws_or_newlines collection_declaration
%type <stringValue> case_list case_item
%type <stringValue> parameter_list parameter_declarations


%nonassoc IF
%nonassoc THEN
%nonassoc ELSE ELIF
%left SEMICOLON
%right ASSIGN_OP
%left ','
%left MEMBER_ACCESS

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
%right UNARY_MINUS
%left '(' ')'
%left '[' ']'
%left '{' '}'

%token <stringValue> ARRAY_DECLARATION

// Add new tokens for function definition
%token <stringValue> FUNCTION_DEF
%token <stringValue> RETURN_TYPE
%token RET

%%

program: 
    statement_list { $$ = $1; }
    ;

statement_list:
    /* empty */               { $$ = strdup(""); }
    | statement_list statement { 
        if ($1 && $2) {
            char *result = malloc(strlen($1) + strlen($2) + 2);
            sprintf(result, "%s\n%s", $1, $2);
            $$ = result;
        } else if ($2) {
            $$ = strdup($2);
        } else if ($1) {
            $$ = strdup($1);
        } else {
            $$ = strdup("");
        }
    }
    ;

statement:
    declaration SEMICOLON    { $$ = strdup(""); }
    | assignment SEMICOLON   { $$ = $1; }
    | expression SEMICOLON   { $$ = $1; }
    | BLOCK_COMMENT         { 
        printf("Block Comment processed in statement\n");
        $$ = strdup(""); 
    }
    | LINE_COMMENT          { 
        printf("Line Comment processed in statement\n");
        $$ = strdup(""); 
    }
    | BREAK SEMICOLON       { $$ = strdup("break"); }
    | CONTINUE SEMICOLON    { $$ = strdup("continue"); }
    | RETURN expression SEMICOLON { $$ = strdup("return"); }
    | if_statement         { $$ = $1; }
    | loop_statement       { $$ = $1; }
    | function_statement   { $$ = strdup(""); }
    | collection_declaration { $$ = $1; }
    | case_statement       { $$ = $1; }
    | block               { $$ = $1; }
    ;

if_statement:
    IF '[' expression ']' block %prec THEN        { $$ = strdup("if"); }
    | if_statement ELSE block             { $$ = strdup("if-else"); }
    | if_statement ELIF '[' expression ']' block  { $$ = strdup("if-elif"); }
    ;

case_statement:
    CASE '[' expression ']' case_block    { $$ = strdup("case"); }
    ;

case_block:
    '{' case_list '}'                     { $$ = strdup("case-block"); }
    ;

case_list:
    case_item                { $$ = $1; }
    | case_list case_item    { 
        char *result = malloc(strlen($1) + strlen($2) + 2);
        sprintf(result, "%s\n%s", $1, $2);
        $$ = result;
    }
    ;

case_item:
    '[' expression ']' ':' statement    { 
        char *result = malloc(strlen($2) + strlen($5) + 32);
        sprintf(result, "case %s: %s", $2, $5);
        $$ = result;
    }
    | '[' ']' ':' statement            { 
        char *result = malloc(strlen($4) + 32);
        sprintf(result, "default: %s", $4);
        $$ = result;
    }
    ;

loop_statement:
    LOOP_TILL '[' expression ']' block    { $$ = strdup("loop_till"); }
    | LOOP_FOR block             { $$ = strdup("loop_for"); }
    ;

block:
    '{' statement_list '}'       { $$ = $2; }
    ;

declaration:
    VARIABLE_DECLARATION ASSIGN_OP expression { 
        initializations++;
        printf("Operation: Variable Declaration with Initialization at line %d\n", line_num);
        $$.name = $1; 
        $$.type = "variable";
        char *var_type = get_variable_type($1);
        char *expr_type = get_type_string($3);
        
        if (!expr_type) {
            char error_msg[100];
            sprintf(error_msg, "Invalid value type for initialization");
            yyerror(error_msg);
            $$.name = "";
        }
        else if (!check_type_compatibility(var_type, expr_type)) {
            char error_msg[100];
            sprintf(error_msg, "Type mismatch in initialization: expected %s, got %s", var_type, expr_type);
            yyerror(error_msg);
            $$.name = "";
        } else {
            printf("Variable Declaration with Initialization: %s of type %s with value %s\n", $1, var_type, $3); 
            add_symbol_with_value($1, var_type, $3);
        }
    }
    | CONSTANT_DECLARATION ASSIGN_OP expression { 
        initializations++;
        printf("Operation: Constant Declaration and Initialization at line %d\n", line_num);
        $$.name = $1; 
        $$.type = "constant"; 
        char *var_type = get_variable_type($1);
        char *expr_type = get_type_string($3);
        
        if (!expr_type) {
            char error_msg[100];
            sprintf(error_msg, "Invalid value type for constant initialization");
            yyerror(error_msg);
            $$.name = "";
        }
        else if (!check_type_compatibility(var_type, expr_type)) {
            char error_msg[100];
            sprintf(error_msg, "Type mismatch in constant initialization: expected %s, got %s", var_type, expr_type);
            yyerror(error_msg);
            $$.name = "";
        } else {
            printf("Constant Declaration: %s of type %s with value %s\n", $1, var_type, $3); 
            add_symbol_with_value($1, var_type, $3);
        }
    }
    | CONSTANT_DECLARATION { 
        yyerror("Constant declaration must have an initializer");
        $$.name = "";
        $$.type = "";
    }
    | VARIABLE_DECLARATION { 
        printf("Operation: Variable Declaration at line %d\n", line_num);
        $$.name = $1; 
        $$.type = "variable"; 
        char *var_type = get_variable_type($1);
        printf("Variable Declaration: %s of type %s\n", $1, var_type); 
        add_symbol($1, var_type);
    }
    | ARRAY_IDENTIFIER { 
        $$.name = $1; 
        $$.type = "array"; 
        char *var_type = get_variable_type($1);
        printf("Array Identifier: %s of type %s[]\n", $1, var_type); 
        add_symbol($1, "array");
    }
    | ARRAY_DECLARATION {
        printf("Operation: Array Declaration at line %d\n", line_num);
        $$.name = $1;
        $$.type = "array";
        char *base_type = get_array_base_type($1);
        char type_with_array[100];
        sprintf(type_with_array, "%s[]", base_type);
        printf("Array Declaration: %s of type %s\n", $1, type_with_array);
        add_symbol($1, type_with_array);
        free(base_type);
    }
    | ARRAY_DECLARATION ASSIGN_OP expression {
        initializations++;
        printf("Operation: Array Declaration with Initialization at line %d\n", line_num);
        $$.name = $1;
        $$.type = "array";
        char *base_type = get_array_base_type($1);
        char type_with_array[100];
        sprintf(type_with_array, "%s[]", base_type);
        
        // Check if expression is an array of the correct type
        if (!check_type_compatibility(type_with_array, $3)) {
            char error_msg[100];
            sprintf(error_msg, "Type mismatch in array initialization: expected %s, got %s", type_with_array, $3);
            yyerror(error_msg);
            $$.name = "";
        } else {
            printf("Array Declaration with Initialization: %s of type %s\n", $1, type_with_array);
            add_symbol($1, type_with_array);
        }
        free(base_type);
    }
    ;

assignment:
    IDENTIFIER ASSIGN_OP expression { 
        assignments++;
        printf("Operation: Assignment at line %d\n", line_num);
        Symbol *sym = find_symbol($1);
        if (!sym) {
            yyerror("Undeclared identifier");
            $$ = strdup("");
        } else {
            char *expr_type = $3;
            if (!check_type_compatibility(sym->data_type, expr_type)) {
                char error_msg[100];
                sprintf(error_msg, "Type mismatch in assignment: expected %s, got %s", sym->data_type, expr_type);
                yyerror(error_msg);
                $$ = strdup("");
            } else {
                $$ = strdup($1);
                printf("Assignment: %s = %s\n", $1, $3); 
            }
        }
    }
    ;

function_statement:
    FUNCTION_DEF parameter_list RETURN_TYPE block { 
        if (find_symbol($1)) {
            yyerror("Duplicate function definition");
            $$.name = "";
            $$.returnType = "";
        } else {
            add_symbol($1, $3);  // Store return type
            define_symbol($1);
            $$.name = $1;
            $$.returnType = $3;
            printf("Function Definition: %s with return type %s\n", $1, $3); 
        }
    }
    | FUNCTION_DEF parameter_list block {
        if (find_symbol($1)) {
            yyerror("Duplicate function definition");
            $$.name = "";
            $$.returnType = "";
        } else {
            add_symbol($1, "void");  // No return type specified
            define_symbol($1);
            $$.name = $1;
            $$.returnType = "void";
            printf("Function Definition: %s with no return type\n", $1); 
        }
    }
    ;

parameter_list:
    '(' ')'                          { $$ = strdup(""); }
    | '(' parameter_declarations ')' { $$ = $2; }
    ;

parameter_declarations:
    VARIABLE_DECLARATION                      { 
        $$ = $1;
        char *var_type = get_variable_type($1);
        printf("Parameter Variable Declaration: %s of type %s\n", $1, var_type);
        add_symbol($1, var_type);
    }
    | ARRAY_DECLARATION                       { 
        $$ = $1;
        char *base_type = get_array_base_type($1);
        char type_with_array[100];
        sprintf(type_with_array, "%s[]", base_type);
        printf("Parameter Array Declaration: %s of type %s\n", $1, type_with_array);
        add_symbol($1, type_with_array);
        free(base_type);
    }
    | CONSTANT_DECLARATION ASSIGN_OP expression {
        char *var_type = get_variable_type($1);
        char *expr_type = get_type_string($3);
        
        if (!expr_type) {
            char error_msg[100];
            sprintf(error_msg, "Invalid value type for constant parameter initialization");
            yyerror(error_msg);
            $$ = "";
        }
        else if (!check_type_compatibility(var_type, expr_type)) {
            char error_msg[100];
            sprintf(error_msg, "Type mismatch in constant parameter initialization: expected %s, got %s", var_type, expr_type);
            yyerror(error_msg);
            $$ = "";
        } else {
            printf("Parameter Constant Declaration: %s of type %s with value %s\n", $1, var_type, $3);
            add_symbol_with_value($1, var_type, $3);
            $$ = $1;
        }
    }
    | CONSTANT_DECLARATION {
        yyerror("Constant parameter declaration must have an initializer");
        $$ = "";
    }
    | parameter_declarations ',' VARIABLE_DECLARATION {
        char *result = malloc(strlen($1) + strlen($3) + 2);
        sprintf(result, "%s,%s", $1, $3);
        $$ = result;
        char *var_type = get_variable_type($3);
        printf("Parameter Variable Declaration: %s of type %s\n", $3, var_type);
        add_symbol($3, var_type);
    }
    | parameter_declarations ',' ARRAY_DECLARATION {
        char *result = malloc(strlen($1) + strlen($3) + 2);
        sprintf(result, "%s,%s", $1, $3);
        $$ = result;
        char *base_type = get_array_base_type($3);
        char type_with_array[100];
        sprintf(type_with_array, "%s[]", base_type);
        printf("Parameter Array Declaration: %s of type %s\n", $3, type_with_array);
        add_symbol($3, type_with_array);
        free(base_type);
    }
    | parameter_declarations ',' CONSTANT_DECLARATION ASSIGN_OP expression {
        char *var_type = get_variable_type($3);
        char *expr_type = get_type_string($5);
        
        if (!expr_type) {
            char error_msg[100];
            sprintf(error_msg, "Invalid value type for constant parameter initialization");
            yyerror(error_msg);
            $$ = $1;  // Keep previous parameters
        }
        else if (!check_type_compatibility(var_type, expr_type)) {
            char error_msg[100];
            sprintf(error_msg, "Type mismatch in constant parameter initialization: expected %s, got %s", var_type, expr_type);
            yyerror(error_msg);
            $$ = $1;  // Keep previous parameters
        } else {
            char *result = malloc(strlen($1) + strlen($3) + 2);
            sprintf(result, "%s,%s", $1, $3);
            $$ = result;
            printf("Parameter Constant Declaration: %s of type %s with value %s\n", $3, var_type, $5);
            add_symbol_with_value($3, var_type, $5);
        }
    }
    ;

expression:
    expr_arithmetic { $$ = $1; }
    | expr_bitwise { $$ = $1; }
    | expr_conditional { $$ = $1; }
    | expr_logical { $$ = $1; }
    | primary_expression { $$ = $1; }
    | expression MEMBER_ACCESS IDENTIFIER { $$ = $1; }
    | ARITHMETIC_OP_MINUS expression %prec UNARY_MINUS { 
        arithmetic_ops++;
        printf("Operation: Unary Minus at line %d\n", line_num);
        $$ = $2; 
    }
    ;

primary_expression:
    INTEGER { 
        char buf[32]; 
        sprintf(buf, "%d", $1); 
        $$ = strdup(buf); 
    }
    | FLOAT { 
        char buf[32]; 
        sprintf(buf, "%.6f", $1); 
        // Remove trailing zeros
        int len = strlen(buf);
        while (len > 0 && buf[len-1] == '0') {
            buf[--len] = '\0';
        }
        if (len > 0 && buf[len-1] == '.') {
            buf[--len] = '\0';
        }
        $$ = strdup(buf); 
    }
    | STRING_LITERAL { 
        $$ = $1; 
    }
    | IDENTIFIER { 
        Symbol *sym = find_symbol($1);
        if (!sym) {
            yyerror("Undeclared identifier");
            $$ = strdup("");
        } else {
            $$ = sym->value ? strdup(sym->value) : strdup($1);
        }
    }
    | '(' expression ')' { 
        $$ = $2; 
    }
    | '[' expression ']' { 
        $$ = $2; 
    }
    ;

expr_arithmetic:
    expression ARITHMETIC_OP_PLUS expression { 
        arithmetic_ops++;
        printf("Operation: Addition at line %d\n", line_num);
        $$ = strdup($1); 
    }
    | expression ARITHMETIC_OP_MINUS expression { 
        arithmetic_ops++;
        printf("Operation: Subtraction at line %d\n", line_num);
        $$ = strdup($1); 
    }
    | expression ARITHMETIC_OP_MULT expression { 
        arithmetic_ops++;
        printf("Operation: Multiplication at line %d\n", line_num);
        $$ = strdup($1); 
    }
    | expression ARITHMETIC_OP_DIV expression { 
        arithmetic_ops++;
        printf("Operation: Division at line %d\n", line_num);
        $$ = strdup($1); 
    }
    ;

expr_bitwise:
    expression BITWISE_OP_AND expression { 
        bitwise_ops++;
        $$ = strdup($1); 
    }
    | expression BITWISE_OP_OR expression { 
        bitwise_ops++;
        $$ = strdup($1); 
    }
    | expression BITWISE_OP_XOR expression { 
        bitwise_ops++;
        $$ = strdup($1); 
    }
    | BITWISE_OP_NOT expression { 
        bitwise_ops++;
        $$ = strdup($2); 
    }
    ;

expr_conditional:
    expression CONDITIONAL_OP_EQ expression { 
        conditional_ops++;
        $$ = strdup($1); 
    }
    | expression CONDITIONAL_OP_LT expression { 
        conditional_ops++;
        $$ = strdup($1); 
    }
    | expression CONDITIONAL_OP_GT expression { 
        conditional_ops++;
        $$ = strdup($1); 
    }
    | expression CONDITIONAL_OP_LE expression { 
        conditional_ops++;
        $$ = strdup($1); 
    }
    | expression CONDITIONAL_OP_GE expression { 
        conditional_ops++;
        $$ = strdup($1); 
    }
    ;

expr_logical:
    expression LOGICAL_OP_AND expression { 
        logical_ops++;
        $$ = strdup($1); 
    }
    | expression LOGICAL_OP_OR expression { 
        logical_ops++;
        $$ = strdup($1); 
    }
    | LOGICAL_OP_NOT expression { 
        logical_ops++;
        $$ = strdup($2); 
    }
    ;

collection_declaration:
    COLLECTION_START members_with_newlines '}' SEMICOLON {
        update_token_pos();
        printf("Collection Definition complete at line %d\n", line_num);
        $$ = strdup($2.name);
    }
    ;

members_with_newlines:
    collection_members                  { $$ = $1; }
    | collection_members ws_or_newlines { $$ = $1; }
    ;

collection_members:
    /* empty */                        { 
        $$.name = strdup("");
        $$.type = "collection";
    }
    | collection_member                { $$ = $1; }
    | collection_members ',' collection_member {
        char *result = malloc(strlen($1.name) + strlen($3.name) + 2);
        sprintf(result, "%s,%s", $1.name, $3.name);
        $$.name = result;
        $$.type = "collection";
    }
    ;

collection_member:
    VARIABLE_DECLARATION {
        update_token_pos();
        $$.name = $1;
        $$.type = "variable";
        char *type = get_variable_type($1);
        printf("Collection Member Variable: %s of type %s\n", $1, type);
        add_symbol($1, type);
    }
    | ARRAY_DECLARATION {
        update_token_pos();
        $$.name = $1;
        $$.type = "array";
        char *base_type = get_array_base_type($1);
        char type_with_array[100];
        sprintf(type_with_array, "%s[]", base_type);
        printf("Collection Member Array: %s of type %s\n", $1, type_with_array);
        add_symbol($1, type_with_array);
        free(base_type);
    }
    ;

ws_or_newlines:
    NEWLINE                  { $$ = strdup(""); }
    | EMPTY_LINE             { $$ = strdup(""); }
    | ws_or_newlines NEWLINE { $$ = strdup(""); }
    | ws_or_newlines EMPTY_LINE { $$ = strdup(""); }
    ;

%%

int main(void) {
    line_num = 1;
    char_num = 1;
    
    int result = yyparse();
    
    printf("\n=== Operation Statistics ===\n");
    printf("Keywords: %d\n", keywords);
    printf("Identifiers: %d\n", identifiers);
    printf("Line Comments: %d\n", line_comments);
    printf("Block Comments: %d\n", block_comments);
    printf("Declarations: %d\n", declarations);
    printf("Initializations: %d\n", initializations);
    printf("Assignments: %d\n", assignments);
    printf("Function Declarations: %d\n", functions);
    printf("Function Calls: %d\n", function_calls);
    printf("Loops: %d\n", loops);
    printf("Conditions: %d\n", conditions);
    printf("Arithmetic Operations: %d\n", arithmetic_ops);
    printf("Bitwise Operations: %d\n", bitwise_ops);
    printf("Logical Operations: %d\n", logical_ops);
    printf("Conditional Operations: %d\n", conditional_ops);
    
    return result;
}