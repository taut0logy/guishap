all: guishap

guishap.tab.c guishap.tab.h: guishap.y
	bison -v -d guishap.y

lex.yy.c: guishap.l guishap.tab.h
	flex guishap.l

guishap: lex.yy.c guishap.tab.c
	gcc -o guishap lex.yy.c guishap.tab.c

run: guishap
	./guishap in.txt

clean:
	rm -f guishap lex.yy.c guishap.tab.c guishap.tab.h guishap.output

.PHONY: all run clean
