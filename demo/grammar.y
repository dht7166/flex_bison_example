%{
/* C includes, definitions, functions, variables, etc. */

#include <stdio.h>
extern int yylex();
extern int yyparse();
void yyerror(char* p);
void declare(char* s,int tt);
void assign(char *s,double v);
double find(char *s);
void print(char *s);


double var[200];
int type[200];



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



/* Define associativity of operators */
%right ASSIGN
%left PLUS MINUS 
%left DIV MUL


/* Define Union */
%union{
	int i;
	double f;
	char* str;
}


/* Define type of tokens */
%type<str> VAR;
%type<i> C_INTEGER;
%type<f> C_REAL;
%type<f> math;
%type<f> expression;
%type<f> const;

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

declaration: 	T_INTEGER VAR 	{declare($2,1);}
				| T_REAL VAR 	{declare($2,2);}
				;

computation:	VAR ASSIGN expression	{assign($1,$3);}
				;

expression:		expression PLUS math 	{$$ = $1 + $3;}
				| expression MINUS math {$$ = $1 - $3;}
				| math 					{$$ = $1;}

math: 			const MUL math          {$$ = $1 * $3;}
				| const DIV math        {$$ = $1 / $3;}
				| const 				{$$ = $1; }
				| VAR 					{$$ = find($1);}


const:			C_REAL
				| C_INTEGER 			{$$ = (float)$1;}
				;


%%
/* Additional C code */

#include "lex.yy.c"	

void yyerror(char* p){
    printf("Line %d: Syntax error %s\n", yylineno, p);
}

void declare(char *s,int tt){
	char name = *s;
	int n = name -'A';
	if (type[n]!=0){
		printf("Line %d: Variable %s already defined.\n",yylineno,s);
	}
	else{
		type[n] = tt;
		printf("Declared %s \n",s);
	}
}

double abs_minus(double a, double b){
	if (a>b)
	return a-b;
	return b-a;
}

void assign(char *s,double v){
	char name = *s;
	int n = name -'A';
	if (type[n] == 1){
		if (abs_minus((int)v,v)>0.0001){
			printf("Warning line %d, casting real to int\n",yylineno);
		}
		var[n] = (int)v;
	}
	else
		var[n] = v;
}
double find(char *s){
	char name = *s;
	int n = name -'A';
	if (type[n]==0){
		printf("Line %d:Undefined variable\n",yylineno);
	}
	return var[n];
}
void print(char *s){
	char name = *s;
	int n = name -'A';
	if (type[n]==0){
		printf("Line %d:Undefined variable\n",yylineno);
	}
	else if(type[n]==1){
		printf("%s = %d\n",s,(int)var[n]);
	}
	else{
		printf("%s = %f\n",s,var[n]);
	}
}

int main(int argc, char *argv[]){
	for(int i = 0;i<200;i++)
		type[i] =0;
    yyparse();
}