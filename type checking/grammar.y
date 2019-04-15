%{
/* C includes, definitions, functions, variables, etc. */

#include <stdio.h>




// Declare type using enum
enum type{INT,REAL,STR};
enum math_op{PL,MN,DI,MU};

struct node
{
	enum type t;
	union{
		int i;
		double f;
		char *s;
	} value;
};

int symtab_size = 0;

struct symtab{
	char name;
	struct node *v;
} st[100]; //Assume that there will be no more than 100 variable (might need to grow the size)


extern int yylex();
extern int yyparse();
void yyerror(char* p);
void declare(char* s,int tt);

struct symtab *find (char *s);

struct node typecheck(struct node l,struct node r, int math_op);

void assign(char *s, struct node eq);

void print(char *s);
%}

%token T_INTEGER
%token T_REAL
%token ADD
%token MINUS
%token MUL
%token DIV
%token ASSIGN
%token C_REAL
%token C_INTEGER
%token VAR
%token L_PARENTHESIS
%token R_PARENTHESIS
%token STRING



/* Define associativity of operators */
%right ASSIGN
%left PLUS MINUS 
%left DIV MUL


/* Define Union */
%union{
	int i;
	double f;
	char* str;
	struct node exp;
}


/* Define type of tokens */
%type<str> VAR;
%type<str> STRING;
%type<exp> const;
%type<exp> math;
%type<exp> expression;
%type<exp> var_const;
%type<f> C_REAL;
%type<i> C_INTEGER; 

/* start symbol */
%start program

%%
/* Grammar rules */

program: 	/* Empty = end*/
			| code program
			;

code: 	declaration
				| computation
				| VAR 			{print($1);}
				;

declaration: 	T_INTEGER VAR 	{declare($2,INT);}
				| T_REAL VAR 	{declare($2,REAL);}
				;

computation:	VAR ASSIGN expression {assign($1,$3);}
				;

expression:		expression PLUS math  {$$ = typecheck($1,$3,PL); }
				| expression MINUS math 	{$$ = typecheck($1,$3,MN); }
				| math 				  {$$ = $1;}

math: 			math MUL var_const     {$$ = typecheck($1,$3,MU); }
				| math DIV var_const   {$$ = typecheck($1,$3,DI); } 
				| var_const 			{$$ = $1;}          
				 
				
var_const:		const 		{$$ = $1;} 			
				| VAR 		{
							struct node *v = find($1)->v; 
							$$.t = v->t;
							switch($$.t){
								case STR:
									$$.value.s = v->value.s;
									break;
								case INT:
									$$.value.i = v->value.i;
									break;
								case REAL:
									$$.value.f = v->value.f;
												break;
							}
							}        			
				| L_PARENTHESIS expression R_PARENTHESIS     {$$ = $2;} 


const:			C_REAL          {$$.t = REAL; $$.value.f = $1;} 
				| C_INTEGER 	{$$.t = INT; $$.value.i = $1;}
				| STRING 		{$$.t = STR; $$.value.s = $1;}
				;


%%
/* Additional C code */

#include "lex.yy.c"	

void yyerror(char* p){
    printf("Line %d: Syntax error %s\n", yylineno, p);
}

/*
This function declare a variable name *s, with type tt (which is an enum)
*/
void declare(char *s,int tt){
	char name = *s;
	for (int i = 0;i<symtab_size;i++){
		if (name == st[i].name){
			printf("Variable %c is already declared\n",st[i].name);
			return;
		}
	}
	st[symtab_size].name = name;
	st[symtab_size].v = malloc(sizeof(struct node));
	st[symtab_size].v->t = tt;
	if (tt == INT){
		printf("Declare %c as integer\n",st[symtab_size].name);
	}
	else{
		printf("Declare %c as float\n",st[symtab_size].name);
	}
	symtab_size++;
}


/* 
This function is used only for assign statement (=),
assign variable *s to value eq
*/
void assign (char *s, struct node eq){
	char name = *s;
	for (int i = 0;i<symtab_size;i++){
		if (name == st[i].name){
			if (st[i].v->t!=eq.t){
				if (st[i].v->t == INT){
					printf("Assign Warning Line %d: Expected type INT, but got type ",yylineno-1);
					switch(eq.t){
						case STR:
							printf("STRING\n.");
							break;
						case REAL:
							st[i].v->value.i = (int) eq.value.f;
							printf("REAL\n");
							break;
						default:
							printf("");
					}
				}
				else{
					printf("Assign Warning Line %d: Expected type REAL, but got type ",yylineno-1);
					switch(eq.t){
						case STR:
							printf("STRING\n.");
							break;
						case INT:
							st[i].v->value.f = (double) eq.value.i;
							printf("INT\n");
							break;
						default:
							printf("");
					}
				}
			}
			else{
				switch (st[i].v->t){
					case INT:
						st[i].v->value.i = eq.value.i;
						break;
					case REAL:
						st[i].v->value.f = eq.value.f;
						break;
				}
			}
			return ;
		}
	}
	printf("ERROR: LINE %d: Variable %c is NOT declared\n",yylineno-1,name);
}

/*
This function do 2 things
1. type checking on expression l and r
2. perform math operation on l and r (code could be greatly reduced if we exclude math operations)
*/
struct node typecheck(struct node l,struct node r, int math_operation){
	if (l.t == r.t){
		struct node result;
		result.t = l.t;
		if (result.t == INT){
			switch (math_operation){
				case PL:
					result.value.i = l.value.i + r.value.i;
					break;
				case MN:
					result.value.i = l.value.i - r.value.i;
					break;
				case DI:
					if (r.value.i == 0){
						printf("Error: Line %d: Cannot perform division on 0\n",yylineno-1);
					}
					else
						result.value.i = l.value.i / r.value.i;
					break;
				case MU:
					result.value.i = l.value.i * r.value.i;
					break;
				default:
					yyerror("");
			}
		}
		else{
			switch (math_operation){
				case PL:
					result.value.f = l.value.f + r.value.f;
					break;
				case MN:
					result.value.f = l.value.f - r.value.f;
					break;
				case DI:
					if (r.value.f == 0){
						printf("Error: Line %d: Cannot perform division on 0\n",yylineno-1);
					}
					else
						result.value.f = l.value.f / r.value.f;
					break;
				case MU:
					result.value.f = l.value.f * r.value.f;
					break;
				default:
					yyerror("");
			}
		}
		return result;
	}
	else if (l.t!=r.t && l.t!=STR && r.t != STR){
		printf("Warning: Line %d: INT and REAL are not of equal type, casting to real\n",yylineno-1);
		struct node result;
		result.t = REAL;
		double ll,rr;
		if (l.t==INT)
			ll = (double)l.value.i;
		else 
			ll = l.value.f;
		if (r.t==INT)
			rr = (double)r.value.i;
		else 
			rr = r.value.f;
		switch (math_operation){
			case PL:
				result.value.f = ll+rr;
				break;
			case MN:
				result.value.f = ll-rr;
				break;
			case DI:
				if (rr == 0){
					printf("Error: Line %d: Cannot perform division on 0\n",yylineno-1);
				}
				else
					result.value.f = ll/rr;
				break;
			case MU:
				result.value.f = ll*rr;
				break;
			default:
				yyerror("");
		}
		return result;
	}
	else{
		printf("Error: Line %d: Cannot perform math on STR type, default output is 0\n",yylineno-1);
		struct node result;
		result.t = INT;
		result.value.i = 0;
		return result;
	}
}

/* 
Find function for symbol table
*/
struct symtab *find(char *s){
	char name = *s;
	for (int i = 0;i<symtab_size;i++){
		if (name == st[i].name){
			return &st[i];
		}
	}
	printf("Variable %c is not declared\n",name);
	return NULL;
}

/*
This function prints the variable to stdout
*/
void print(char *s){
	char name = *s;
	for (int i = 0;i<symtab_size;i++){
		if (name == st[i].name){
			printf("%c = ",st[i].name);
			switch(st[i].v->t){
				case INT:
					printf("%d\n",st[i].v->value.i);
					break;
				case REAL:
					printf("%f\n",st[i].v->value.f);
					break;
				default:
					printf("Something wrong happened!\n");
			}
			return;
		}
	}
}

int main(int argc, char *argv[]){
    yyparse();
}