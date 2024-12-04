%option noyywrap
%option yylineno

%{
#include <stdio.h>
#define YY_DECL int yylex()
#include "parser.tab.h"

int numLines = 1; int numCharacters = 1;

char *create_string(char *text, int len) {
  //char *string_value = new char[len + 1];
  char *string_value = (char *)malloc((len + 1) * sizeof(char));
  if(string_value == NULL){
        fprintf(stderr, "Memory allocation failed\n");
        exit(1);
  }
  strcpy(string_value, text);
  return string_value;
}

%}

DIGIT [0-9]
ALPHA [a-zA-Z]
COMMENT #.*\n

%%
"func"              {return FUNC_KEYWORD; numCharacters += yyleng;}
"return"            {return RETURN_KEYWORD; numCharacters += yyleng;}
"integer"           {return INT_KEYWORD; numCharacters += yyleng;}
"("                 {return LEFT_PAREN; numCharacters += yyleng;}
")"                 {return RIGHT_PAREN; numCharacters += yyleng;}
"{"                 {return LEFT_CURLY; numCharacters += yyleng;}
"}"                 {return RIGHT_CURLY; numCharacters += yyleng;}
"["                 {return LEFT_BRACKET; numCharacters += yyleng;}
"]"                 {return RIGHT_BRACKET; numCharacters += yyleng;}
"plus"              {return ADD; numCharacters += yyleng;}
"minus"             {return SUBTRACT; numCharacters += yyleng;}
"times"             {return MULTIPLY; numCharacters += yyleng;}
"dividedby"         {return DIVIDE; numCharacters += yyleng;}
"mod"               {return MODULUS; numCharacters += yyleng;}
"equal"             {return EQUAL; numCharacters += yyleng;}
"print"             {return PRINT_KEYWORD; numCharacters += yyleng;}
"read"              {return READ_KEYWORD; numCharacters += yyleng;}
"break"             {return BREAK_KEYWORD; numCharacters += yyleng;}
"while"             {return WHILE_KEYWORD; numCharacters += yyleng;}
"isless"            {return LESS_KEYWORD; numCharacters += yyleng;}
"isless/isequal"    {return LESSEQUAL_KEYWORD; numCharacters += yyleng;}
"isgreater/isequal" {return GREATEREQUAL_KEYWORD; numCharacters += yyleng;}
"isgreater"         {return GREATER_KEYWORD; numCharacters += yyleng;}
"equalequal"        {return EQUALITY_KEYWORD; numCharacters += yyleng;}
"notequal"          {return NOTEQUAL_KEYWORD; numCharacters += yyleng;}
";"                 {return SEMICOLON_KEYWORD; numCharacters += yyleng;}
","                 {return COMMA_KEYWORD; numCharacters += yyleng;}
"if"                {return IF_KEYWORD; numCharacters += yyleng;}
"else"              {return ELSE_KEYWORD; numCharacters += yyleng;}
"continue"          {return CONTINUE_KEYWORD; numCharacters += yyleng;}


{ALPHA}+              {yylval.op_value = create_string(yytext, yyleng); numCharacters += yyleng; return IDENT;}
{DIGIT}+              {yylval.op_value = create_string(yytext, yyleng); return DIGIT;}
{COMMENT}             {}
[a-zA-Z]"_"           {printf("Error at line %d, column %d: identifier %s cannot end in an underscore\n", numLines, numCharacters, yytext); exit(1);}
[0-9][a-zA-Z]         {printf("Error at line %d, column %d: identifier %s must begin with an letter\n", numLines, numCharacters, yytext); exit(1);}
\n                    {++numLines; numCharacters = 1;}
[ \n\t]               {numCharacters += yyleng;}
.                     {printf("Error at line %d, column %d: unrecognized symbol \"%s\"\n", numLines, numCharacters, yytext); exit(1);}


%%
