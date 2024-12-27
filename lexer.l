%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "guishap.tab.h"

int keywords = 0;
int identifiers = 0;
int declarations = 0;
int operators = 0;
int loops = 0;
int functions = 0;
int conditions = 0;
int semicolons = 0;
int line_comments = 0;
int block_comments = 0;
int constants = 0;
int collections = 0;
int arrays = 0;

int line_num = 1;
int char_num = 1;

FILE *outp;
%}

%%

/* Keywords and Types */
"int"|"float"|"bool"|"char"|"string" { keywords++; fprintf(outp, "KEYWORD: %s\n", yytext); return KEYWORD; }

/* Collection Definition */
"col"[ \t]+[A-Z][a-zA-Z0-9_]*[ \t]*[{] { collections++; keywords++; fprintf(outp, "COLLECTION: %s\n", yytext); return COLLECTION; }

/* Variable and Constant Declarations */
"__"[a-zA-Z][a-zA-Z0-9_]*"%"[a-zA-Z]+ { constants++; declarations++; fprintf(outp, "CONSTANT DECLARATION: %s\n", yytext); return CONSTANT_DECLARATION; }
"_"[a-zA-Z][a-zA-Z0-9_]*"%"[a-zA-Z]+ { identifiers++; declarations++; fprintf(outp, "VARIABLE DECLARATION: %s\n", yytext); return VARIABLE_DECLARATION; }
"_"[a-zA-Z][a-zA-Z0-9_]*"%"[a-zA-Z]+"\[\]" { identifiers++; arrays++; fprintf(outp, "ARRAY_IDENTIFIER: %s\n", yytext); return ARRAY_IDENTIFIER; }

/* Loops */
"loop"[ \t]+"till" { loops++; keywords++; fprintf(outp, "LOOP_TILL: %s\n", yytext); return LOOP_TILL; }
"loop"[ \t]+"_"[a-zA-Z][a-zA-Z0-9_]*"%"[a-zA-Z]+[ \t]+"for" { loops++; keywords++; declarations++; fprintf(outp, "LOOP_FOR: %s\n", yytext); return LOOP_FOR; }
"loop"[ \t]+[a-zA-Z][a-zA-Z0-9_]*[ \t]+"for" { loops++; keywords++; identifiers++; fprintf(outp, "LOOP_FOR: %s\n", yytext); return LOOP_FOR; }
"break" { keywords++; fprintf(outp, "BREAK\n"); return BREAK; }
"continue" { keywords++; fprintf(outp, "CONTINUE\n"); return CONTINUE; }

/* Functions */
"shap"[ \t]+[a-zA-Z][a-zA-Z0-9_]* { functions++; keywords++; fprintf(outp, "FUNCTION: %s\n", yytext); return FUNCTION; }
"ret" { keywords++; fprintf(outp, "RETURN\n"); return RETURN; }

/* Conditions */
"if"[ \t]*"[" { conditions++; keywords++; fprintf(outp, "IF\n"); return IF; }
"elif"[ \t]*"[" { conditions++; keywords++; fprintf(outp, "ELIF\n"); return ELIF; }
"else" { conditions++; keywords++; fprintf(outp, "ELSE\n"); return ELSE; }

/* Case Statement */
"case"[ \t]*"[" { conditions++; keywords++; fprintf(outp, "CASE\n"); return CASE; }

/* Comments */
"##"[^#]*"##" { block_comments++; fprintf(outp, "BLOCK_COMMENT\n"); return BLOCK_COMMENT; }
"#"[^\n]* { line_comments++; fprintf(outp, "LINE_COMMENT\n"); return LINE_COMMENT; }

/* Operators */
"=="|"<="|">="|"!="|"<"|">" { operators++; fprintf(outp, "CONDITIONAL_OPERATOR: %s\n", yytext); return CONDITIONAL_OPERATOR; }
"&&"|"||"|"!" { operators++; fprintf(outp, "LOGICAL_OPERATOR: %s\n", yytext); return LOGICAL_OPERATOR; }
"&"|"|"|"~"|"^^" { operators++; fprintf(outp, "BITWISE_OPERATOR: %s\n", yytext); return BITWISE_OPERATOR; }
"+"|"-"|"*"|"/"|"%" { operators++; fprintf(outp, "ARITHMETIC_OPERATOR: %s\n", yytext); return ARITHMETIC_OPERATOR; }

/* Range Operator */
".." { operators++; fprintf(outp, "RANGE_OPERATOR\n"); return RANGE_OPERATOR; }

/* Separators */
";" { semicolons++; fprintf(outp, "SEMICOLON\n"); return SEMICOLON; }
[{}(),\[\]] { fprintf(outp, "SEPARATOR: %s\n", yytext); return SEPARATOR; }

/* String Literals */
\"[^\"]*\" { fprintf(outp, "STRING_LITERAL: %s\n", yytext); return STRING_LITERAL; }

/* Numbers */
[0-9]+(\.[0-9]+)? { fprintf(outp, "NUMBER: %s\n", yytext); return NUMBER; }

/* Member Access */
"."[a-zA-Z][a-zA-Z0-9_]* { fprintf(outp, "MEMBER_ACCESS: %s\n", yytext); return MEMBER_ACCESS; }

/* Identifiers */
[a-zA-Z][a-zA-Z0-9_]* { fprintf(outp, "IDENTIFIER: %s\n", yytext); return IDENTIFIER; }

/* Whitespace */
[ \t]+ { char_num += yyleng; }
\n { line_num++; char_num = 1; }

/* Catch any other character */
. { fprintf(outp, "UNKNOWN TOKEN: %s\n", yytext); return UNKNOWN; }

%%

int main() {
    FILE *inp = fopen("in.txt", "r");
    if (!inp) {
        perror("Error opening in.txt");
        return 1;
    }
    yyin = inp;

    outp = fopen("out.txt", "w");
    if (!outp) {
        perror("Error opening out.txt");
        fclose(inp);
        return 1;
    }

    yylex();

    fprintf(outp, "\nToken Counts:\n");
    fprintf(outp, "-------------\n");
    fprintf(outp, "Keywords: %d\n", keywords);
    fprintf(outp, "Declarations: %d\n", declarations);
    fprintf(outp, "Identifiers: %d\n", identifiers);
    fprintf(outp, "Constants: %d\n", constants);
    fprintf(outp, "Operators: %d\n", operators);
    fprintf(outp, "Arrays: %d\n", arrays);
    fprintf(outp, "Loops: %d\n", loops);
    fprintf(outp, "Functions: %d\n", functions);
    fprintf(outp, "Conditions: %d\n", conditions);
    fprintf(outp, "Collections: %d\n", collections);
    fprintf(outp, "Semicolons: %d\n", semicolons);
    fprintf(outp, "Line Comments: %d\n", line_comments);
    fprintf(outp, "Block Comments: %d\n", block_comments);

    fclose(inp);
    fclose(outp);
    return 0;
}

int yywrap() {
    return 1;
}