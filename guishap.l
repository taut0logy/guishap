%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "guishap.tab.h"

// Global variables for scope tracking
int line_number = 1;
int scope_level = 0;
char current_function[256] = "";
char current_collection[256] = "";
int in_function_params = 0;
int in_loop = 0;
char error_line_buffer[1024] = "";
int error_column = 0;

// Function declarations
void update_error_location(void);
void count_newlines(const char* text);

%}

%option noyywrap
%option yylineno

DIGIT       [0-9]
LETTER      [a-zA-Z]
ID          [a-zA-Z_][a-zA-Z0-9_]*
WS          [ \t\r]+

%%

"col"           { update_error_location(); return COL; }
"shap"          { update_error_location(); in_function_params = 1; return SHAP; }
"ret"           { update_error_location(); return RET; }
"loop"{WS}"till" { update_error_location(); in_loop = 1; return LOOP_TILL; }
"loop"          { update_error_location(); in_loop = 1; return LOOP; }
"for"           { update_error_location(); return FOR; }
"break"         { update_error_location(); return BREAK; }
"continue"      { update_error_location(); return CONTINUE; }
"if"            { update_error_location(); return IF; }
"elif"          { update_error_location(); return ELIF; }
"else"          { update_error_location(); return ELSE; }
"case"          { update_error_location(); return CASE; }
"void"          { update_error_location(); return TYPE_VOID; }
"int"           { update_error_location(); return TYPE_INT; }
"float"         { update_error_location(); return TYPE_FLOAT; }
"string"        { update_error_location(); return TYPE_STRING; }
"bool"          { update_error_location(); return TYPE_BOOL; }

"__"{LETTER}{ID}*"%"{ID} {
    update_error_location();
    yylval.sval = strdup(yytext);
    return CONST_DECL;
}

"_"{LETTER}{ID}*"%"{ID}"[]" {
    update_error_location();
    yylval.sval = strdup(yytext);
    return ARRAY_DECL;
}

"_"{LETTER}{ID}*"%"{ID} {
    update_error_location();
    yylval.sval = strdup(yytext);
    return VAR_DECL;
}

{DIGIT}+        { 
    update_error_location(); 
    yylval.ival = atoi(yytext); 
    return INTEGER; 
}

{DIGIT}+"."{DIGIT}+ { 
    update_error_location(); 
    yylval.fval = atof(yytext); 
    return FLOAT; 
}

{ID}            { 
    update_error_location();
    yylval.sval = strdup(yytext); 
    return IDENTIFIER; 
}

\"[^\"]*\"      { 
    update_error_location(); 
    yylval.sval = strdup(yytext); 
    return STRING; 
}

":"             { update_error_location(); return ASSIGN; }
"{"             { update_error_location(); return '{'; }
"}"             { update_error_location(); return '}'; }
"("             { update_error_location(); return '('; }
")"             { 
    update_error_location();
    if (in_function_params) in_function_params = 0;
    return ')'; 
}
";"             { 
    update_error_location();
    if (in_loop) in_loop = 0;
    return ';'; 
}
","             { update_error_location(); return ','; }
"."             { update_error_location(); return '.'; }
".."            { update_error_location(); return RANGE; }
">"             { update_error_location(); return '>'; }
"["             { update_error_location(); return '['; }
"]"             { update_error_location(); return ']'; }

"+"             { update_error_location(); return '+'; }
"-"             { update_error_location(); return '-'; }
"*"             { update_error_location(); return '*'; }
"/"             { update_error_location(); return '/'; }
"%"             { update_error_location(); return '%'; }
"&"             { update_error_location(); return '&'; }
"|"             { update_error_location(); return '|'; }
"^"             { update_error_location(); return '^'; }
"~"             { update_error_location(); return '~'; }
"=="            { update_error_location(); return EQ; }
"<"             { update_error_location(); return LT; }
">"             { update_error_location(); return GT; }
"<="            { update_error_location(); return LE; }
">="            { update_error_location(); return GE; }
"&&"            { update_error_location(); return AND; }
"||"            { update_error_location(); return OR; }
"!"             { update_error_location(); return NOT; }

"##"[^#]*"##"   { count_newlines(yytext); }
"#"[^\n]*       { update_error_location(); }

{WS}            { update_error_location(); }

\n              { 
    line_number++; 
    error_line_buffer[0] = '\0';
    error_column = 0;
}

.               { 
    update_error_location();
    printf("Error: Unexpected character '%s' at line %d:\n", yytext, line_number);
    printf("%s\n", error_line_buffer);
    printf("%*s^\n", error_column-1, "");
}

%%

void count_newlines(const char* text) {
    for (int i = 0; text[i] != '\0'; i++) {
        if (text[i] == '\n') {
            line_number++;
            error_line_buffer[0] = '\0';
            error_column = 0;
        }
    }
}

void update_error_location(void) {
    if (strlen(error_line_buffer) < sizeof(error_line_buffer) - 1) {
        strcat(error_line_buffer, yytext);
    }
    error_column += strlen(yytext);
}