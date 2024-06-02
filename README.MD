To run the project, execute the command : 

lex  -t interplex.l > interplex.c;yacc  interp.y;mv -f y.tab.c interp.c;cc    -c -o interp.o interp.c;cc   interp.o   -o interp;rm interp.o interp.c;./interp ncounter.txt