all:
	make clean
	flex lexical.lex
	bison -v grammar.y
	gcc  -o compiler grammar.tab.c 
	./compiler < input.txt 

clean:
	rm -f *.o
	rm -f a.out
	rm -f lexer
	rm -f lex.yy.c
	rm -f *.tab.c
	rm -f *.tab.h
	rm -f *.output
	rm -f compiler