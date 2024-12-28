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

FILE *outp;
%}


%%
"int"|"float"|"bool"|"char"|"string" { keywords++; fprintf(outp, "KEYWORD: %s\n", yytext); }

"col"[ \t]+[A-Z][a-zA-Z0-9_]*[ \t]*[{] { 
    collections++; 
    keywords++;
    fprintf(outp, "COLLECTION: %s\n", yytext);
}

"__"[a-zA-Z][a-zA-Z0-9_]*"%"[a-zA-Z]+    { constants++; declarations++; fprintf(outp, "CONSTANT DECLARATION: %s\n", yytext); }
"_"[a-zA-Z][a-zA-Z0-9_]*"%"[a-zA-Z]+     { identifiers++; declarations++; fprintf(outp, "VARIABLE DECLARATION: %s\n", yytext); }
"_"[a-zA-Z][a-zA-Z0-9_]*"%"[a-zA-Z]+"\[\]" {
    identifiers++; 
    arrays++; 
    fprintf(outp, "ARRAY_IDENTIFIER: %s\n", yytext); 
}

"loop"[ \t]+"till"    { loops++; keywords++; fprintf(outp, "LOOP_TILL: %s\n", yytext); }
"loop"[ \t]+"_"[a-zA-Z][a-zA-Z0-9_]*"%"[a-zA-Z]+[ \t]+"for"     { loops++; keywords++; declarations; fprintf(outp, "LOOP_FOR: %s\n", yytext); }
"loop"[ \t]+[a-zA-Z][a-zA-Z0-9_]*[ \t]+"for"     { loops++; keywords++; identifiers; fprintf(outp, "LOOP_FOR: %s\n", yytext); }
"break"               { keywords++; fprintf(outp, "BREAK\n"); }
"continue"            { keywords++; fprintf(outp, "CONTINUE\n"); }

"shap"[ \t]+[a-zA-Z][a-zA-Z0-9_]*  {
    functions++; 
    keywords++; 
    fprintf(outp, "FUNCTION: %s\n", yytext);
}
"ret"                { keywords++; fprintf(outp, "RETURN\n"); }

"if"[ \t]*"["        { conditions++; keywords++; fprintf(outp, "IF\n"); }
"elif"[ \t]*"["      { conditions++; keywords++; fprintf(outp, "ELIF\n"); }
"else"               { conditions++; keywords++; fprintf(outp, "ELSE\n"); }

"case"[ \t]*"["      { conditions++; keywords++; fprintf(outp, "CASE\n"); }

"##"[^#]*"##"        { block_comments++; fprintf(outp, "BLOCK_COMMENT\n"); }
"#"[^\n]*            { line_comments++; fprintf(outp, "LINE_COMMENT\n"); }

":"|">="|"<="|"!="|"=="|">"|"<"|"+" { operators++; fprintf(outp, "OPERATOR: %s\n", yytext); }
"-"|"*"|"/"|"%"|"^"|"&"|"|"|"~"     { operators++; fprintf(outp, "OPERATOR: %s\n", yytext); }

".."                 { operators++; fprintf(outp, "RANGE_OPERATOR\n"); }

";"                  { semicolons++; fprintf(outp, "SEMICOLON\n"); }
[{}(),\[\]]         { fprintf(outp, "SEPARATOR: %s\n", yytext); }

\"[^\"]*\"          { fprintf(outp, "STRING_LITERAL: %s\n", yytext); }

[0-9]+(\.[0-9]+)?   { fprintf(outp, "NUMBER: %s\n", yytext); }

"."[a-zA-Z][a-zA-Z0-9_]* { fprintf(outp, "MEMBER_ACCESS: %s\n", yytext); }

[a-zA-Z][a-zA-Z0-9_]* { fprintf(outp, "IDENTIFIER: %s\n", yytext); }

[ \t\n]+            { /* Ignore whitespace */ }

.    { fprintf(outp, "UNKNOWN TOKEN: %s\n", yytext); }

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