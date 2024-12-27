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

// Helper function to create and return string values
char* make_string(char* text) {
    return strdup(text);
}
%}

%%

"int"|"float"|"bool"|"char"|"string" { 
    keywords++; 
    fprintf(outp, "KEYWORD: %s\n", yytext); 
    yylval.stringValue = make_string(yytext);
    return KEYWORD; 
}

"col"[ \t]+[A-Z][a-zA-Z0-9_]*[ \t]*[{] { 
    collections++; 
    keywords++; 
    fprintf(outp, "COLLECTION: %s\n", yytext);
    yylval.stringValue = make_string(yytext);
    return COLLECTION; 
}

"__"[a-zA-Z][a-zA-Z0-9_]*"%"[a-zA-Z]+ { 
    constants++; 
    declarations++; 
    fprintf(outp, "CONSTANT DECLARATION: %s\n", yytext);
    yylval.stringValue = make_string(yytext);
    return CONSTANT_DECLARATION; 
}

"_"[a-zA-Z][a-zA-Z0-9_]*"%"[a-zA-Z]+ { 
    identifiers++; 
    declarations++; 
    fprintf(outp, "VARIABLE DECLARATION: %s\n", yytext);
    yylval.stringValue = make_string(yytext);
    return VARIABLE_DECLARATION; 
}

"_"[a-zA-Z][a-zA-Z0-9_]*"%"[a-zA-Z]+"\[\]" { 
    identifiers++; 
    arrays++; 
    fprintf(outp, "ARRAY_IDENTIFIER: %s\n", yytext);
    yylval.stringValue = make_string(yytext);
    return ARRAY_IDENTIFIER; 
}

"loop"[ \t]+"till" { 
    loops++; 
    keywords++; 
    fprintf(outp, "LOOP_TILL: %s\n", yytext);
    return LOOP_TILL; 
}

"loop"[ \t]+"for" { 
    loops++; 
    keywords++; 
    fprintf(outp, "LOOP_FOR: %s\n", yytext);
    return LOOP_FOR; 
}

"break" { 
    keywords++; 
    fprintf(outp, "BREAK\n"); 
    return BREAK; 
}

"continue" { 
    keywords++; 
    fprintf(outp, "CONTINUE\n"); 
    return CONTINUE; 
}

"shap"[ \t]+[a-zA-Z][a-zA-Z0-9_]* { 
    functions++; 
    keywords++; 
    fprintf(outp, "FUNCTION: %s\n", yytext);
    yylval.stringValue = make_string(yytext);
    return FUNCTION; 
}

"ret" { 
    keywords++; 
    fprintf(outp, "RETURN\n"); 
    return RETURN; 
}

"if"[ \t]*"[" { 
    conditions++; 
    keywords++; 
    fprintf(outp, "IF\n"); 
    return IF; 
}

"elif"[ \t]*"[" { 
    conditions++; 
    keywords++; 
    fprintf(outp, "ELIF\n"); 
    return ELIF; 
}

"else" { 
    conditions++; 
    keywords++; 
    fprintf(outp, "ELSE\n"); 
    return ELSE; 
}

"case"[ \t]*"[" { 
    conditions++; 
    keywords++; 
    fprintf(outp, "CASE\n"); 
    return CASE; 
}

"##"[^#]*"##" { 
    block_comments++; 
    fprintf(outp, "BLOCK_COMMENT\n"); 
    return BLOCK_COMMENT; 
}

"#"[^\n]* { 
    line_comments++; 
    fprintf(outp, "LINE_COMMENT\n"); 
    return LINE_COMMENT; 
}

"+" { operators++; fprintf(outp, "ARITHMETIC_OP_PLUS\n"); return ARITHMETIC_OP_PLUS; }
"-" { operators++; fprintf(outp, "ARITHMETIC_OP_MINUS\n"); return ARITHMETIC_OP_MINUS; }
"*" { operators++; fprintf(outp, "ARITHMETIC_OP_MULT\n"); return ARITHMETIC_OP_MULT; }
"/" { operators++; fprintf(outp, "ARITHMETIC_OP_DIV\n"); return ARITHMETIC_OP_DIV; }

"&" { operators++; fprintf(outp, "BITWISE_OP_AND\n"); return BITWISE_OP_AND; }
"|" { operators++; fprintf(outp, "BITWISE_OP_OR\n"); return BITWISE_OP_OR; }
"~" { operators++; fprintf(outp, "BITWISE_OP_NOT\n"); return BITWISE_OP_NOT; }
"^^" { operators++; fprintf(outp, "BITWISE_OP_XOR\n"); return BITWISE_OP_XOR; }

"==" { operators++; fprintf(outp, "CONDITIONAL_OP_EQ\n"); return CONDITIONAL_OP_EQ; }
"<" { operators++; fprintf(outp, "CONDITIONAL_OP_LT\n"); return CONDITIONAL_OP_LT; }
">" { operators++; fprintf(outp, "CONDITIONAL_OP_GT\n"); return CONDITIONAL_OP_GT; }
"<=" { operators++; fprintf(outp, "CONDITIONAL_OP_LE\n"); return CONDITIONAL_OP_LE; }
">=" { operators++; fprintf(outp, "CONDITIONAL_OP_GE\n"); return CONDITIONAL_OP_GE; }

"&&" { operators++; fprintf(outp, "LOGICAL_OP_AND\n"); return LOGICAL_OP_AND; }
"||" { operators++; fprintf(outp, "LOGICAL_OP_OR\n"); return LOGICAL_OP_OR; }
"!" { operators++; fprintf(outp, "LOGICAL_OP_NOT\n"); return LOGICAL_OP_NOT; }

";" { 
    semicolons++; 
    fprintf(outp, "SEMICOLON\n"); 
    return SEMICOLON; 
}

[{}(),\[\]] { 
    fprintf(outp, "SEPARATOR: %s\n", yytext); 
    return yytext[0];  // Return the character itself for single-char tokens
}

\"[^\"]*\" { 
    fprintf(outp, "STRING_LITERAL: %s\n", yytext);
    yylval.stringValue = make_string(yytext);
    return STRING_LITERAL; 
}

[0-9]+ { 
    fprintf(outp, "INTEGER: %s\n", yytext);
    yylval.intValue = atoi(yytext);
    return INTEGER; 
}

[0-9]+\.[0-9]+ { 
    fprintf(outp, "FLOAT: %s\n", yytext);
    yylval.floatValue = atof(yytext);
    return FLOAT; 
}

[a-zA-Z][a-zA-Z0-9_]* { 
    fprintf(outp, "IDENTIFIER: %s\n", yytext);
    yylval.stringValue = make_string(yytext);
    return IDENTIFIER; 
}

[ \t]+ { char_num += yyleng; }
\n { line_num++; char_num = 1; return '\n'; }

. { fprintf(outp, "UNKNOWN TOKEN: %s\n", yytext); }

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