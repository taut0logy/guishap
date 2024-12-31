%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "guishap.tab.h"

int line_num = 1;
int char_num = 1;
int line_comments = 0;
int block_comments = 0;
int declarations = 0;
int functions = 0;
int collections = 0;
int arrays = 0;
int identifiers = 0;
int keywords = 0;
int operators = 0;
int loops = 0;
int conditions = 0;
int semicolons = 0;

void update_char_pos() {
    char_num += yyleng;
}

void handle_newline() {
    line_num++;
    char_num = 1;
}

char* get_value_type(const char* value) {
    if (value[0] == '"') return "string";
    
    int has_dot = 0;
    int all_digits = 1;
    for (int i = 0; value[i] != '\0'; i++) {
        if (value[i] == '.') {
            if (has_dot) {
                all_digits = 0;
                break;
            }
            has_dot = 1;
        } else if (!isdigit(value[i]) && (i > 0 || value[i] != '-')) {
            all_digits = 0;
            break;
        }
    }
    
    if (all_digits) {
        if (has_dot) return "float";
        return "int";
    }
    
    return NULL;
}

char* float_to_string(float value) {
    char* str = malloc(32);
    sprintf(str, "%.6f", value);
    int len = strlen(str);
    while (len > 0 && str[len-1] == '0') {
        str[--len] = '\0';
    }
    if (len > 0 && str[len-1] == '.') {
        str[--len] = '\0';
    }
    return str;
}

%}

%x BLOCK_COMMENT
%x COLLECTION_DEF

%%

[ \t]+          { update_char_pos(); }
\n              { handle_newline(); }

"##"            { 
    block_comments++; 
    update_char_pos();
    printf("Block Comment start at line %d\n", line_num);
    BEGIN(BLOCK_COMMENT); 
}
<BLOCK_COMMENT>"##" { 
    update_char_pos();
    printf("Block Comment end at line %d\n", line_num);
    BEGIN(INITIAL); 
}
<BLOCK_COMMENT>\n   { handle_newline(); }
<BLOCK_COMMENT>.    { update_char_pos(); }

"#"[^\n]*       { 
    line_comments++; 
    update_char_pos();
    printf("Line Comment at line %d: %s\n", line_num, yytext + 1);  // Skip the '#' character
    return LINE_COMMENT; 
}

"col"[ \t]+[A-Z][a-zA-Z0-9_]*[ \t]*"{" { 
    collections++; 
    keywords++; 
    char* name = strdup(yytext + 4);  // Skip "col "

    while (isspace(name[strlen(name)-1]) || name[strlen(name)-1] == '{') {
        name[strlen(name)-1] = '\0';
    }

    while (isspace(*name)) name++;
    
    printf("Collection Definition start at line %d: %s\n", line_num, name);
    yylval.stringValue = name;
    update_char_pos();
    return COLLECTION_START; 
}

"shap"[ \t]+[a-zA-Z][a-zA-Z0-9_]*[ \t]* {
    update_char_pos();
    functions++;
    keywords++;
    char* name = strdup(yytext + 5);  // Skip "shap "
    while (isspace(*name)) name++;     // Skip leading spaces
    
    name[strlen(name)-1] = '\0';
    while (isspace(name[strlen(name)-1])) {
        name[strlen(name)-1] = '\0';
    }
    
    printf("Function Definition start at line %d: %s\n", line_num, name);
    yylval.stringValue = name;
    return FUNCTION_DEF;
}

[ \t]*">"[ \t]*[a-zA-Z][a-zA-Z0-9_]*[ \t]* {
    update_char_pos();
    char* type = strdup(yytext + 1);  // Skip ">"
    while (isspace(*type)) type++;
    
    while (isspace(type[strlen(type)-1])) {
        type[strlen(type)-1] = '\0';
    }
    
    printf("Function return type at line %d: %s\n", line_num, type);
    yylval.stringValue = type;
    return RETURN_TYPE;
}

"ret"           { update_char_pos(); keywords++; return RET; }
"loop_till"     { update_char_pos(); loops++; return LOOP_TILL; }
"loop_for"      { update_char_pos(); loops++; return LOOP_FOR; }
"break"         { update_char_pos(); keywords++; return BREAK; }
"continue"      { update_char_pos(); keywords++; return CONTINUE; }
"return"        { update_char_pos(); keywords++; return RETURN; }
"if"            { update_char_pos(); conditions++; return IF; }
"elif"          { update_char_pos(); conditions++; return ELIF; }
"else"          { update_char_pos(); conditions++; return ELSE; }
"case"          { update_char_pos(); conditions++; return CASE; }

"__"[a-zA-Z][a-zA-Z0-9_]*"%"[a-zA-Z_][a-zA-Z0-9_]* {
    update_char_pos();
    declarations++;
    yylval.stringValue = strdup(yytext);
    return CONSTANT_DECLARATION;
}

"_"[a-zA-Z][a-zA-Z0-9_]*"%"[a-zA-Z_][a-zA-Z0-9_]*"[]" {
    update_char_pos();
    arrays++;
    declarations++;
    yylval.stringValue = strdup(yytext);
    return ARRAY_DECLARATION;
}

"_"[a-zA-Z][a-zA-Z0-9_]*"%"[a-zA-Z_][a-zA-Z0-9_]* {
    update_char_pos();
    declarations++;
    yylval.stringValue = strdup(yytext);
    return VARIABLE_DECLARATION;
}

[0-9]+"."[0-9]+ { 
    update_char_pos(); 
    yylval.floatValue = atof(yytext);
    yylval.stringValue = float_to_string(yylval.floatValue);
    return FLOAT; 
}

[0-9]+          { 
    update_char_pos(); 
    yylval.intValue = atoi(yytext);
    yylval.stringValue = strdup(yytext);
    return INTEGER; 
}

\"[^\"]*\"      { update_char_pos(); yylval.stringValue = strdup(yytext); return STRING_LITERAL; }

[a-zA-Z_][a-zA-Z0-9_]* {
    update_char_pos();
    identifiers++;
    yylval.stringValue = strdup(yytext);
    return IDENTIFIER;
}

"+"             { update_char_pos(); operators++; return ARITHMETIC_OP_PLUS; }
"-"             { update_char_pos(); operators++; return ARITHMETIC_OP_MINUS; }
"*"             { update_char_pos(); operators++; return ARITHMETIC_OP_MULT; }
"/"             { update_char_pos(); operators++; return ARITHMETIC_OP_DIV; }

"&"             { update_char_pos(); operators++; return BITWISE_OP_AND; }
"|"             { update_char_pos(); operators++; return BITWISE_OP_OR; }
"~"             { update_char_pos(); operators++; return BITWISE_OP_NOT; }
"^"             { update_char_pos(); operators++; return BITWISE_OP_XOR; }

"=="            { update_char_pos(); operators++; return CONDITIONAL_OP_EQ; }
"<"             { update_char_pos(); operators++; return CONDITIONAL_OP_LT; }
">"             { update_char_pos(); operators++; return CONDITIONAL_OP_GT; }
"<="            { update_char_pos(); operators++; return CONDITIONAL_OP_LE; }
">="            { update_char_pos(); operators++; return CONDITIONAL_OP_GE; }

"&&"            { update_char_pos(); operators++; return LOGICAL_OP_AND; }
"||"            { update_char_pos(); operators++; return LOGICAL_OP_OR; }
"!"             { update_char_pos(); operators++; return LOGICAL_OP_NOT; }

"."             { update_char_pos(); operators++; return MEMBER_ACCESS; }
";"             { update_char_pos(); semicolons++; return SEMICOLON; }
"{"             { update_char_pos(); return '{'; }
"}"             { update_char_pos(); return '}'; }
"["             { update_char_pos(); return '['; }
"]"             { update_char_pos(); return ']'; }
"("             { update_char_pos(); return '('; }
")"             { update_char_pos(); return ')'; }
","             { update_char_pos(); return ','; }
":"             { update_char_pos(); operators++; return ASSIGN_OP; }

.               { update_char_pos(); /* ignore other characters */ }

%%

int yywrap(void) {
    return 1;
}