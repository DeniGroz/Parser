%{

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <math.h>
#include <iostream>
#include <vector>
#include <sstream>
#include <string>
extern int yylex();
extern int yyparse();
extern FILE* yyin;

int counter = 0;
int loop_count = 0;

void yyerror(const char* s) {
	extern int yylineno;
  	fprintf(stderr, "Error at line %d: %s \n", yylineno, s);
}
enum Type { Integer, Array };
struct CodeNode {
	std::string code;
	std::string name;
};
struct Symbol {
  std::string name;
  Type type;
};
struct Function {
  std::string name;
  std::vector<Symbol> declarations;
};

  



std::string create_temp() { 
  static int num = 0;
  std::string value = "_temp" + std::to_string(num);
  num+=1;
  return value;
}

std::string create_if() {
  static int num = 0;
  std::string value = "_if" + std::to_string(num);
  num+=1;
  return value;
}

std::string create_else() {
  static int num = 0;
  std::string value = "_else" + std::to_string(num);
  num+=1;
  return value;
}
std::string create_endstatement() {
  static int num = 0;
  std::string value = "_endifstatement" + std::to_string(num);
  num+=1;
  return value;
}

std::string create_bloop() {
  static int num = 0;
  std::string value = "beginloop" + std::to_string(num);
  num+=1;
  return value;
}

std::string create_eloop() {
  static int num = 0;
  std::string value = "endloop" + std::to_string(num);
  num+=1;
  return value;
}

std::string create_loopbody() {
  static int num = 0;
  std::string value = "loopbody" + std::to_string(num);
  num+=1;
  return value;
}

std::string decl_temp_code(std::string &temp) {
  return std::string(". ") + temp + std::string("\n");
}

std::vector <Function> symbol_table;
std::vector <Function> tracker;
std::vector <std::string> endloop;

void addloopend(std::string end)
{
  endloop.push_back(end);
}

std::string poploopend()
{
  int size = endloop.size();
        if(size > 0)
        {
                std::string temp = endloop.at(endloop.size()-1);
                endloop.pop_back();

                return temp;
        }
        return "error";

}

Function *get_function() {
  int last = symbol_table.size()-1;
if (last < 0) {
    printf("***Error. Attempt to call get_function with an empty symbol table\n");
    printf("Create a 'Function' object using 'add_function_to_symbol_table' before\n");
    printf("calling 'find' or 'add_variable_to_symbol_table'");
    exit(1);
  }
  return &symbol_table[last];
}

bool has_function(std::string &value) {
  bool check = false;
  for(int i = 0; i < symbol_table.size(); ++i) {
     Function *f = &symbol_table[i];
     if(f->name == value) {
       check = true;
    }
  }
  return check;
}

bool find(std::string &value) {
  Function *f = get_function();
  for(int i=0; i < f->declarations.size(); i++) {
    Symbol *s = &f->declarations[i];
    if (s->name == value) {
      return true;
    }
  }
  return false;
}

bool check_if_int(std::string &value) {
  Function *f = get_function();
  for(int i=0; i < f->declarations.size(); i++) {
    Symbol *s = &f->declarations[i];
    if (s->name == value) {
      if(s->type == Integer) {
        return true;
      }
    }
  }
  return false;
}

bool check_if_array(std::string &value) {
  Function *f = get_function();
  for(int i=0; i < f->declarations.size(); i++) {
    Symbol *s = &f->declarations[i];
    if (s->name == value) {
      if(s->type == Array) {
        return true;
      }
    }
  }
  return false;
}

bool has_main() {
  bool check = false;
  for(int i = 0; i < symbol_table.size(); ++i) {
     Function *f = &symbol_table[i];
     if(f->name == "main") {
       check = true;
    }
  }
  return check; 
}

void add_function_to_symbol_table(std::string &value) {
  Function f;
  tracker.push_back(f);
  f.name = value;
  symbol_table.push_back(f);
}

void add_variable_to_symbol_table(std::string &value, Type t) {
  Symbol s;
  s.name = value;
  s.type = t;
  Function *f = get_function();
  f->declarations.push_back(s);
}

void print_symbol_table(void) {
  printf("symbol table:\n");
  printf("--------------------\n");
  for(int i=0; i<symbol_table.size(); i++) {
   printf("function: %s\n", symbol_table[i].name.c_str());
    for(int j=0; j<symbol_table[i].declarations.size(); j++) {
      printf("  locals: %s\n", symbol_table[i].declarations[j].name.c_str());
    }
  }
  printf("--------------------\n");
}

%}

%union {
  char *op_value;
  struct CodeNode *code_node;
}

%locations
%define parse.error verbose
%define parse.lac full

%token FUNC_KEYWORD
%token RETURN_KEYWORD
%token INT_KEYWORD
%token LEFT_PAREN RIGHT_PAREN
%token LEFT_CURLY RIGHT_CURLY
%token LEFT_BRACKET RIGHT_BRACKET

%left ADD SUBTRACT 
%left MULTIPLY DIVIDE MODULUS

%token EQUAL
%token PRINT_KEYWORD
%token READ_KEYWORD
%token WHILE_KEYWORD
%token LESS_KEYWORD
%token GREATER_KEYWORD
%token LESSEQUAL_KEYWORD
%token GREATEREQUAL_KEYWORD
%token EQUALITY_KEYWORD
%token NOTEQUAL_KEYWORD
%token SEMICOLON_KEYWORD
%token COMMA_KEYWORD
%token IF_KEYWORD
%token ELSE_KEYWORD
%token CONTINUE_KEYWORD
%token <op_value> DIGIT
%token UNKNOWN_TOKEN
%token <op_value> IDENT
%token <op_value> BREAK_KEYWORD
%start program
%type <code_node> term

%type <code_node> functions
%type <code_node> variable
%type <code_node> function
%type <code_node> statements
%type <code_node> statement
%type <code_node> parameters
%type <code_node> parameter
%type <code_node> multi_exp
%type <code_node> expression
%type <code_node> comp
%type <code_node> bool_exp
%type <code_node> while_begin
%type <op_value> function_header

%%

program: functions {
  struct CodeNode *node = $1;
	if(!has_main()) {
		yyerror("main function is not defined");	
	}
  printf("%s\n", node->code.c_str());
}

functions : function functions {
	struct CodeNode *function = $1;
	struct CodeNode *functions = $2;
	struct CodeNode* node = new CodeNode;
	node->code = function->code + functions->code;
	$$ = node;
}
	  | %empty {
	struct CodeNode *node = new CodeNode;
	$$ = node;
}

function_header: FUNC_KEYWORD IDENT {
	std::string name = $2;
	add_function_to_symbol_table(name);
	$$ = $2;
}
   
function: function_header LEFT_PAREN parameters RIGHT_PAREN LEFT_CURLY statements RIGHT_CURLY {
	struct CodeNode *node = new CodeNode;
	struct CodeNode *statements = $6;
	struct CodeNode *parameters = $3;
	node->code = std::string("func ") + std::string($1) + std::string("\n");
	node->code += parameters->code;
	node->code += statements->code;
	node->code += std::string("endfunc\n\n");
	$$ = node;
}
   
statements: statement statements {
	struct CodeNode *statement = $1;
	struct CodeNode *statements = $2;
	struct CodeNode *node = new CodeNode;
	node->code = statement->code + statements->code;
	$$ = node;
}
	| %empty {
	  	struct CodeNode *node = new CodeNode;
  		$$ = node;
}

parameters: parameter {
  CodeNode *node = new CodeNode;
  struct CodeNode *parameter = $1;
  node->code = parameter->code;
  node->name = parameter->name;
  $$ = node;
}
| parameter COMMA_KEYWORD parameters{
  CodeNode *node = new CodeNode;
  struct CodeNode *parameter = $1;
  struct CodeNode *parameters = $3;
  //node->code = std::string("FIX PARAMETER -> parameter , parameter\n");
  node->code = parameter->code;
  node->code += parameters->code;
  node->code += std::string("= ") + parameter->name + std::string(", $0") + std::string("\n");
  node->code += std::string("= ") + parameters->name + std::string(", $1") + std::string("\n");
  $$ = node;
}
| %empty {
  struct CodeNode *node = new CodeNode;
  $$ = node;
}

parameter: INT_KEYWORD IDENT {
  std::string name = $2;
  if(find(name)) {
     yyerror("Defining an already defined variable");
  }
  add_variable_to_symbol_table(name, Integer);
  CodeNode *node = new CodeNode;
  node->code = std::string(". ") +std::string($2) + std::string("\n");
  node->name = $2;
  $$ = node;
}

statement: INT_KEYWORD IDENT SEMICOLON_KEYWORD {
  // int a; -> . a
  std::string name = $2;
  if(find(name)) {
     yyerror("Defining an already defined variable");
  }
  add_variable_to_symbol_table(name, Integer);
  struct CodeNode *node = new CodeNode;
  node->code = std::string(". ") + std::string($2) + std::string("\n");
  $$ = node;
}
| IDENT EQUAL expression SEMICOLON_KEYWORD {
  std::string var_name = $1;
  if(check_if_array(var_name)) {
     yyerror("Trying to access an array variable as an integer");
  }
  CodeNode *node = new CodeNode;
  node->code = $3->code;
  node->code+= std::string("= ") + var_name + std::string(", ") + $3->name + std::string("\n");
  $$ = node;
}
| IDENT LEFT_BRACKET expression RIGHT_BRACKET EQUAL expression SEMICOLON_KEYWORD {
	std::string var_name = $1;
	if(check_if_int(var_name)) {
	   yyerror("Trying to access an integer variable as an array");
	}
	CodeNode *node = new CodeNode;
	node->code = $3->code + $6->code;
	node->code += std::string("[]= ") + std::string($1) + std::string(", ") + $3->name + std::string(", ") + $6->name + std::string("\n");
	$$=node;
}
| IF_KEYWORD bool_exp LEFT_CURLY statements RIGHT_CURLY {
  CodeNode *node = new CodeNode;
        struct CodeNode *statements = $4;
        struct CodeNode *bool_exp = $2;
        std::string temp = create_temp();
        std::string iftemp = create_if();
        //std::string elsetemp = create_else();
        std::string endtemp = create_endstatement();

        node->code = std::string(": if\n");
        node->code += bool_exp->code;
        //node->code += std::string("?:= beginif, ") + bool_exp->name + std::string("\n");
        node->code += std::string("?:= ") + iftemp + std::string(", ") + bool_exp->name + std::string("\n");
        node->code += std::string(":= ") + endtemp + std::string("\n");
        node->code += std::string(": ") + iftemp + std::string("\n");
        node->code += statements->code;
        node->code += std::string(":= ") + endtemp + std::string("\n");
        //node->code += std::string(": ") + elsetemp + std::string("\n");
        //node->code += $8->code;
        node->code += std::string(": ") + endtemp + std::string("\n");
        $$ = node;

}
| WHILE_KEYWORD while_begin bool_exp LEFT_CURLY statements RIGHT_CURLY {
  struct CodeNode *node = new CodeNode;
  struct CodeNode *statements = $5;
  struct CodeNode *while_begin = $2;
  struct CodeNode *bool_exp = $3;
  //std::string eloop = create_eloop();
  std::string bloop = create_bloop();
  //addloopend(eloop);
  std::string body = create_loopbody();
  node->code += std::string(": ") + bloop + std::string("\n");
  node->code += $3->code;
  node->code+=std::string("?:= ") + body + std::string(", ") + $3->name + std::string("\n");
  //node->code += std::string(":= ") + eloop + std::string("\n");
  node->code += std::string(":= ") + while_begin->name + std::string("\n");
  node->code += std::string(": ") + body + std::string("\n");
  node->code +=statements->code;
  node->code += std::string(":= ") + bloop + std::string("\n");
  //node->code += std::string(": ") + eloop + std::string("\n"); 
  node->code += std::string(": ") + while_begin->name + std::string("\n");
  loop_count--; 
  $$ = node;
}
| IF_KEYWORD bool_exp LEFT_CURLY statements RIGHT_CURLY ELSE_KEYWORD LEFT_CURLY statements RIGHT_CURLY{

  CodeNode *node = new CodeNode;
        struct CodeNode *statements = $4;
        struct CodeNode *bool_exp = $2;
        std::string temp = create_temp();
        std::string iftemp = create_if();
        std::string elsetemp = create_else();
        std::string endtemp = create_endstatement();

        node->code = std::string(": if\n");
        node->code += bool_exp->code;
        //node->code += std::string("?:= beginif, ") + bool_exp->name + std::string("\n");
        node->code += std::string("?:= ") + iftemp + std::string(", ") + bool_exp->name + std::string("\n");
        node->code += std::string(":= ") + elsetemp + std::string("\n");
        node->code += std::string(": ") + iftemp + std::string("\n");
        node->code += statements->code;
        node->code += std::string(":= ") + endtemp + std::string("\n");
        node->code += std::string(": ") + elsetemp + std::string("\n");
        node->code += $8->code;
        node->code += std::string(": ") + endtemp + std::string("\n");
        $$ = node;
}
| READ_KEYWORD variable {}
| RETURN_KEYWORD expression SEMICOLON_KEYWORD {
  // return a plus b -> ret _temp0
  CodeNode *node = new CodeNode;
  struct CodeNode *expression = $2;
  node->code = expression->code;
  node->code += std::string("ret ") + expression->name + std::string("\n");
  $$ = node;
}
| PRINT_KEYWORD LEFT_PAREN term RIGHT_PAREN SEMICOLON_KEYWORD { 
  // print(a) => .> a
  struct CodeNode *node = new CodeNode;
  node->code += $3->code;
  node->code += std::string(".> ") + std::string($3->name) + std::string("\n");
  node->name += $3->name;
  $$ = node;
}
| BREAK_KEYWORD SEMICOLON_KEYWORD{
  if (loop_count < 1){
	yyerror("Break statement not in loop");
}  
  struct CodeNode *node = new CodeNode;
  node->code = std::string(":= ") + poploopend() + std::string("\n");
  $$ = node;

}
| CONTINUE_KEYWORD SEMICOLON_KEYWORD{
  if (loop_count < 1){
        yyerror("Continue statement not in loop");
}
  struct CodeNode *node = new CodeNode;
  node->code = std::string(": ") + std::string("continue") + std::string("\n");
  $$ = node;

}
| INT_KEYWORD LEFT_BRACKET DIGIT RIGHT_BRACKET IDENT SEMICOLON_KEYWORD {
  //FIX: Grab value of arg 3 to check array size 
  std::string name = $5;
  if(find(name)) {
     yyerror("Defining an already defined variable");
  }
  if(atoi($3) <= 0) {
     yyerror("Trying to define an array of size <= 0");
  }
  add_variable_to_symbol_table(name, Array);
  struct CodeNode *node = new CodeNode;
  node->code = std::string(".[] ") + std::string($5) + std::string(", ") + std::string($3) + std::string("\n");
  $$ = node;
}
;
while_begin: %empty{
  struct CodeNode *node = new CodeNode;
  std::string eloop = create_eloop();
  node->name = eloop;
  addloopend(eloop);
  loop_count++;
  $$ = node;
}

bool_exp: NOTEQUAL_KEYWORD expression comp expression {}
| expression comp expression {
std::string temp = create_temp();
  CodeNode *node = new CodeNode;
  struct CodeNode *multi_exp1 = $1;
  struct CodeNode *multi_exp2 = $3;
 // node->code += decl_temp_code(temp);
  node->code = $1->code + $3->code + decl_temp_code(temp);
  node->code += $2->code  + temp + std::string(", ") + $1->name + std::string(", ") + $3->name + std::string("\n");
  node->name = temp;
  $$ = node;

}

comp: EQUALITY_KEYWORD {
  CodeNode *node = new CodeNode;
  node->code = std::string("== ");
  $$ = node;
}
| LESSEQUAL_KEYWORD {
  CodeNode *node = new CodeNode;
  node->code = std::string("<= ");
  $$ = node;
}
| GREATEREQUAL_KEYWORD {
  CodeNode *node = new CodeNode;
  node->code = std::string(">= ");
  $$ = node;
}
| LESS_KEYWORD {
  CodeNode *node = new CodeNode;
  node->code += std::string("< ");
  $$ = node;
}
| GREATER_KEYWORD {
  CodeNode *node = new CodeNode;
  node->code = std::string("> ");
}

expression: multi_exp {
  struct CodeNode *multi_exp = $1;
  struct CodeNode *node = new CodeNode;
  node->code = multi_exp->code;
  node->name = multi_exp->name;
  $$ = node;
}
| multi_exp ADD multi_exp {
  std::string temp = create_temp();
  CodeNode *node = new CodeNode;
  struct CodeNode *multi_exp1 = $1;
  struct CodeNode *multi_exp2 = $3;
  //node->code += decl_temp_code(temp);
  node->code += decl_temp_code(temp);
  node->code += std::string("+ ") + temp + std::string(", ") + $1->name + std::string(", ") + $3->name + std::string("\n");
  node->code+=  $1->code + $3->code; 
  node->name = temp;
  $$ = node;
}
| multi_exp SUBTRACT multi_exp{
  std::string temp = create_temp();
  CodeNode *node = new CodeNode;
  node->code =$1->code + $3->code + decl_temp_code(temp);
  node->code += std::string("- ") + temp + std::string(", ") + $1->name + std::string(", ") + $3->name + std::string("\n");
  node->name = temp;
  $$ = node;
}
| expression COMMA_KEYWORD expression {
  CodeNode *node = new CodeNode;
  struct CodeNode *expression1 = $1;
  struct CodeNode *expression2 = $3;
  node->code = expression1->code;
  node->code += std::string("param ") + expression1->name + std::string("\n");
  node->code += expression2->code;
  node->code += std::string("param ") + expression2->name + std::string("\n");
  $$ = node;
}

multi_exp: term MODULUS term{
  std::string temp = create_temp();
  CodeNode *node = new CodeNode;
  node->code = $1->code + $3->code + decl_temp_code(temp);
  node->code += std::string("% ") + temp + std::string(", ") + $1->name + std::string(", ") + $3->name + std::string("\n");
  node->name = temp;
  $$ = node;
}
| term DIVIDE term{
  std::string temp = create_temp();
  CodeNode *node = new CodeNode;
  node->code = $1->code + $3->code + decl_temp_code(temp);
  node->code += std::string("/ ") + temp + std::string(", ") + $1->name + std::string(", ") + $3->name + std::string("\n");
  node->name = temp;
  $$ = node;
}
| term MULTIPLY term{
  std::string temp = create_temp();
  CodeNode *node = new CodeNode;
  struct CodeNode *term1 = $1;
  struct CodeNode *term2 = $3;
  node->code = $1->code + $3->code + decl_temp_code(temp);
  node->code += std::string("* ") + temp + std::string(", ") + $1->name + std::string(", ") + $3->name + std::string("\n");
  node->name = temp;
  $$ = node;
}
| term {
  CodeNode *node = new CodeNode;
  struct CodeNode *term = $1;
  node->code = term->code;
  node->name = term->name;
  $$ = node;
}

term: variable {
  CodeNode *node = new CodeNode;
  struct CodeNode *variable = $1;
  node->code = variable->code;
  node->name = variable->name;
  $$ = node;
}
| DIGIT {
  CodeNode *node = new CodeNode;
  node->name = $1;
  $$ = node;
}
| LEFT_PAREN expression RIGHT_PAREN {
  struct CodeNode *multi_exp = $2;
  struct CodeNode *node = new CodeNode;
  node->code = multi_exp->code;
  node->name = multi_exp->name;
  $$ = node;

}
| IDENT LEFT_PAREN expression RIGHT_PAREN {
  std::string funcName = $1;
  if(!has_function(funcName)) {
     yyerror("Calling a function that has not been defined");
  }
  std::string temp = create_temp();
  CodeNode *node = new CodeNode;
  struct CodeNode *expression = $3;
  node->code = expression->code;
  node->code += decl_temp_code(temp);
  node->code += std::string("call ") + std::string($1) + std::string(", ") + temp + std::string("\n");
  node->name = temp;
  $$ = node;
}
;

variable: IDENT {
  CodeNode *node = new CodeNode;
  node->name = $1;
  if (!find(node->name)) {
     yyerror("Undeclared identifier");
  }
  $$ = node;
}
| IDENT LEFT_BRACKET expression RIGHT_BRACKET {
  std::string varName = $1;
  if (!find(varName)) {
    yyerror("Undeclared identifier");
  }	
  std::string temp = create_temp();
  CodeNode *node = new CodeNode;
  node->code = decl_temp_code(temp);
  node->code += $3->code;
  node->code += std::string("=[] ") + temp  + std::string(", ") + std::string($1) + std::string(", ") + $3->name +std::string("\n");
  node->name =  temp;
  $$ = node;
  }
;

%%


int main(int argc, char** argv) {
  yyin = stdin;

  bool interactive = true;
  if (argc >= 2){
        FILE *file_ptr = fopen(argv[1], "r");
        if (file_ptr == NULL) {
            printf("Could not open file: %s\n", argv[1]);
            exit(1);
        }
        yyin = file_ptr;
        interactive = false;
  }
  yyparse();
  print_symbol_table();
}