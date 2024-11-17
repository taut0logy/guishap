%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int keywords = 0;
int identifiers = 0;
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

FILE *outp;
%}

%x BLOCK_COMMENT
%x STRING

%%
    /* Keywords and Types */
"int"|"float"|"bool"|"char"|"string" { keywords++; fprintf(outp, "KEYWORD: %s\n", yytext); }

    /* Collection Definition */
"col"[ \t]+[A-Z][a-zA-Z0-9_]*[ \t]*[{] { 
    collections++; 
    keywords++;
    fprintf(outp, "COLLECTION: %s\n", yytext);
}

    /* Variable and Constant Declarations */
"__"[a-zA-Z][a-zA-Z0-9_]*"%"[a-zA-Z]+    { constants++; fprintf(outp, "CONSTANT: %s\n", yytext); }
"_"[a-zA-Z][a-zA-Z0-9_]*"%"[a-zA-Z]+     { identifiers++; fprintf(outp, "IDENTIFIER: %s\n", yytext); }
"_"[a-zA-Z][a-zA-Z0-9_]*"%"[a-zA-Z]+"\[\]" { 
    identifiers++; 
    arrays++; 
    fprintf(outp, "ARRAY_IDENTIFIER: %s\n", yytext); 
}

    /* Loops */
"loop"[ \t]+"till"    { loops++; keywords++; fprintf(outp, "LOOP_TILL: %s\n", yytext); }
"loop"[ \t]+"for"     { loops++; keywords++; fprintf(outp, "LOOP_FOR: %s\n", yytext); }
"break"               { keywords++; fprintf(outp, "BREAK\n"); }
"continue"            { keywords++; fprintf(outp, "CONTINUE\n"); }

    /* Functions */
"shap"[ \t]+[a-zA-Z][a-zA-Z0-9_]*  { 
    functions++; 
    keywords++; 
    fprintf(outp, "FUNCTION: %s\n", yytext);
}
"ret"                 { keywords++; fprintf(outp, "RETURN\n"); }

    /* Conditions */
"if"[ \t]*"["        { conditions++; keywords++; fprintf(outp, "IF\n"); }
"elif"[ \t]*"["      { conditions++; keywords++; fprintf(outp, "ELIF\n"); }
"else"               { conditions++; keywords++; fprintf(outp, "ELSE\n"); }

    /* Case Statement */
"case"[ \t]*"["      { conditions++; keywords++; fprintf(outp, "CASE\n"); }

    /* Comments */
"##"[^#]*"##"        { block_comments++; fprintf(outp, "BLOCK_COMMENT\n"); }
"#"[^\n]*            { line_comments++; fprintf(outp, "LINE_COMMENT\n"); }

    /* Operators */
":"|">="|"<="|"!="|"=="|">"|"<"|"+" { operators++; fprintf(outp, "OPERATOR: %s\n", yytext); }
"-"|"*"|"/"|"%"|"^"|"&"|"|"|"~"     { operators++; fprintf(outp, "OPERATOR: %s\n", yytext); }

    /* Range Operator */
".."                 { operators++; fprintf(outp, "RANGE_OPERATOR\n"); }

    /* Separators */
";"                  { semicolons++; fprintf(outp, "SEMICOLON\n"); }
[{}(),\[\]]         { fprintf(outp, "SEPARATOR: %s\n", yytext); }

    /* String Literals */
\"[^\"]*\"          { fprintf(outp, "STRING_LITERAL: %s\n", yytext); }

    /* Numbers */
[0-9]+(\.[0-9]+)?   { fprintf(outp, "NUMBER: %s\n", yytext); }

    /* Member Access */
"."[a-zA-Z][a-zA-Z0-9_]* { fprintf(outp, "MEMBER_ACCESS: %s\n", yytext); }

    /* Identifiers */
[a-zA-Z][a-zA-Z0-9_]* { fprintf(outp, "IDENTIFIER: %s\n", yytext); }

    /* Whitespace */
[ \t\n]+            { /* Ignore whitespace */ }

    /* Catch any other character */
.                   { fprintf(outp, "UNKNOWN: %s\n", yytext); }

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