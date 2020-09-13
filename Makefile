CFLAGS = -ansi -DNDEBUG -O3 -s -flto -march=native

all: bf

bf: bf.c
	$(CC) $(CFLAGS) -o $@ $< 

clean:
	$(RM) bf

.PHONY: all clean
