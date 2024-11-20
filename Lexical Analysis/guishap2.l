%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

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

int line_number = 1; // Line number tracker
int column_number = 1; // Column number tracker
int in_collection = 0; // Flag for collection definition context

FILE *outp;

void report_error(const char *message, const char *token) {
    fprintf(stderr, "Syntax Error at Line %d, Column %d: %s (near '%s')\n", 
            line_number, column_number, message, token);
}
%}

%%
    /* Keywords and Types */
"int"|"float"|"bool"|"char"|"string" { 
    keywords++; 
    fprintf(outp, "KEYWORD: %s\n", yytext); 
    column_number += yyleng;
}

    /* Newline tracking */
\n { 
    line_number++; 
    column_number = 1; 
}

    /* Collection Start */
"col"[ \t]+[A-Z][a-zA-Z0-9_]*[ \t]*[{] { 
    collections++; 
    keywords++;
    in_collection = 1; // Enter collection context
    fprintf(outp, "COLLECTION START: %s\n", yytext);
    column_number += yyleng;
}

    /* Collection Member */
"_"[a-zA-Z][a-zA-Z0-9_]*"%"[a-zA-Z]+ { 
    if (in_collection) {
        identifiers++; 
        fprintf(outp, "COLLECTION MEMBER: %s\n", yytext);
    } else {
        report_error("Collection member outside collection context", yytext);
    }
    column_number += yyleng;
}

    /* Collection Member Separator */
"," { 
    if (in_collection) {
        fprintf(outp, "COLLECTION MEMBER SEPARATOR: %s\n", yytext);
    } else {
        report_error("Unexpected comma outside collection context", yytext);
    }
    column_number += yyleng;
}

    /* Collection End */
"}" { 
    if (in_collection) {
        in_collection = 0; // Exit collection context
        fprintf(outp, "COLLECTION END: %s\n", yytext);
    } else {
        report_error("Unexpected closing brace outside collection", yytext);
    }
    column_number += yyleng;
}

    /* Variable and Constant Declarations */
"__"[a-zA-Z][a-zA-Z0-9_]*"%"[a-zA-Z]+    { 
    constants++; declarations++; 
    fprintf(outp, "CONSTANT DECLARATION: %s\n", yytext); 
    column_number += yyleng;
}
"_"[a-zA-Z][a-zA-Z0-9_]*"%"[a-zA-Z]+     { 
    identifiers++; declarations++; 
    fprintf(outp, "VARIABLE DECLARATION: %s\n", yytext); 
    column_number += yyleng;
}

    /* Comments */
"##"[^#]*"##"        { 
    block_comments++; 
    fprintf(outp, "BLOCK_COMMENT\n"); 
    column_number += yyleng;
}
"#"[^\n]*            { 
    line_comments++; 
    fprintf(outp, "LINE_COMMENT\n"); 
    column_number += yyleng;
}

    /* Catch any other character */
.    { 
    report_error("Unexpected token", yytext);
    column_number += yyleng;
}

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
