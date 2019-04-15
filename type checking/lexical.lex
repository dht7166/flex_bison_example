
digit 		[0-9]+
integer 	("+"|"-")?{digit}+
real        ("+"|"-")?{digit}+"."{digit}+
var 		[a-zA-Z]
string      \"[a-zA-Z]*\"

%option yylineno
%option noyywrap

%%
"("				{return L_PARENTHESIS;}
")"				{return R_PARENTHESIS;}
"+"				{return PLUS;}
"-"				{return MINUS;}
"*"				{return MUL;}
"/"				{return DIV;}
"="				{return ASSIGN;}
"integer"		{return T_INTEGER;}
{integer}		{yylval.i = atoi(yytext); return C_INTEGER;}
"real"			{return T_REAL;}
{real}			{yylval.f = atof(yytext); return C_REAL;}
[ \t\n\r]			{;}
{var}			{char *s = strdup(yytext); yylval.str = s; return VAR;}
{string}		{char *s = strdup(yytext); yylval.str = s; return STRING;}


%%


#include <stdio.h>

void lexer(){
	int token;
	token = yylex();
	while(token){
		
		printf("%3d %d %s\n", token, yylineno,yytext);

		token = yylex();
	}
}
