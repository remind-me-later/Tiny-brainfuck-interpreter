# Tiny brainfuck interpreter

A brainfuck interpreter written in only 181 characters, mostly as an exercise
in obfuscation. It is not fast though, it executes mandelbrot.b in a whooping 
2 minutes and 18 seconds and, of course, it doesn't make any attempt to 
validate its input so in case it is handed an invalid bf program it 
will fail gracefully by crashing spectacularly. 
With that said here's the full source code

```c
c[999],*d=c,*e,_;main(a,b)int**b;{char*r=1[b];for(;_=*r++%93;a&&(*d+=_==43,*d-=_==45,d+=_==62,d-=_==60,_-46||write(1,d,1),_-44||read(0,d,1)),_-91||(main(*d,&r-1),r=*d?r-1:e));e=r;}
```

The brainfuck code is read directly from the interpreter arguments, 
so to make its use easier a shell script named 'bf.sh' is supplied. 
The script simply prints the file passed as argument as the argument 
to the interpreter, for example to interpret the program in the file
`hello.b` we do

```
$ ./bf.sh hello.b
Hello World!
```

## Making

Simply type `make`, it requires the `unistd.h` header to work.

## Explanation

The code is written in C89 since it allows some tricks. One of such is the use
of implicit function declarations, that's why we don't need any includes,
and the use of implicit int so all variable declarations without type will be
treated as ints. Other tricks used allowed by all versions of C are
short circuiting of logical operators and heavy use of the comma operator.
The most exotic feature of the C language used to make this interpreter
possible is recursion in the main function.

To understand the code first lets make some manipulations to make it more
readable, starting by breaking it into different lines and adding whitespace

```c
c[999], *d = c, *e, _;

main(a,b)
int **b;
{
    char *r = 1[b];
    
    for (;
        _ = *r++ % 93;
        a && (
            *d += _ == 43,
            *d -= _ == 45,
             d += _ == 62,
             d -= _ == 60,
            _ - 46 || write(1, d, 1),
            _ - 44 || read(0, d, 1)
            ),
        _ - 91 || (main(*d, &r - 1), r = *d ? r - 1 : e)
        )
        ;
    
    e = r;
}
```

Now we can explicitly define the variables and give them representative names

```c
int cells[999];
int *cell_pointer = cells;
int *loop_end;
int cur_symbol;

main(int execute, int **program)
{
    char *program_counter = program[1];
    
    for (;
        cur_symbol = *program_counter++ % 93; /* for condition */
        execute && (
            *cell_pointer += cur_symbol == 43,
            *cell_pointer -= cur_symbol == 45,
             cell_pointer += cur_symbol == 62,
             cell_pointer -= cur_symbol == 60,
            cur_symbol - 46 || write(1, cell_pointer, 1),
            cur_symbol - 44 || read(0, cell_pointer, 1)
            ),
        cur_symbol - 91 || (main(*cell_pointer, &program_counter - 1), 
            program_counter = *cell_pointer ? program_counter - 1 : loop_end)
        )
        /* empty for */;
    
    loop_end = program_counter;
}
```

Some observations, a not very well known feature of the C language is that
we can access an array element by the notations `arr[index]` and `index[array]`
so the `1[b]` above is the same as `b[1]`, also `_` is a valid identifier 
in C :smiley:.

The astute reader will already have noticed that the random two digit numbers
sprinkled around the program are in fact the ASCII encodings of some 
characters, let's replace those, add some clarifying parentheses and the
include directives

```c
#include <unistd.h>

int cells[999];
int *cell_pointer = cells;
int *loop_end;
int cur_symbol;

main(int execute, int **program)
{
    char *program_counter = program[1];
    
    for (;
        cur_symbol = *program_counter++ % ']'; /* for condition */
        execute && (
            *cell_pointer += (cur_symbol == '+'),
            *cell_pointer -= (cur_symbol == '-'),
             cell_pointer += (cur_symbol == '>'),
             cell_pointer -= (cur_symbol == '<'),
            cur_symbol - '.' || write(1, cell_pointer, 1),
            cur_symbol - ',' || read(0, cell_pointer, 1)
            ),
        cur_symbol - '[' || (main(*cell_pointer, &program_counter - 1), 
            program_counter = *cell_pointer ? program_counter - 1 : loop_end))
        /* empty for */;
    
    loop_end = program_counter;
}
```

By now it should be pretty clear how the interpreter works, but let's explain
anyway.

The first argument in main is used as a boolean that indicates if we have to
execute the program or not, at the beginning of the execution this number is
not 0 since both the name of the program and the bf code will be passed, 
this value will be important in subsequent recursive calls to `main`, s
ince main is called recursively to handle loops. 

The second is a pointer to the arguments passed to the interpreter which
should contain the name of the interpreter and the bf code to interpret.

In the first line we set the program counter to
point to the first character in the passed bf code

```c
char *program_counter = program[1];
```

this counter is different for every main call so we can alter it and 
still have a pointer to the beginning of the loop in the previous main
call.

The for loop is the main loop of the interpreter, the exit condition is 
```c
cur_symbol = *program_counter++ % ']';
```
that is the char pointed to by the program counter is equal to '\0',
end of the program, or ']', end of the current loop. We also assign the char
to `current_symbol` and increment the value of `program_counter` for the next 
iteration.

We handle all the interpreter logic in the postcondition of the loop, first
we check if we have to interpret the code, if we do all the data manipulation
is handled the same way, so let's see how one of them works

```c
*cell_pointer += (cur_symbol == '+'),
```

this simply increments the char pointed by cell_pointer by one if the symbol is
'+', this is done by an implicit cast to bool when comparing the equality
between the current symbol and '+', all other cases are analogous.

The '.' and ',' symbols are handled a bit differently since we have to call
functions to write or read

```c
cur_symbol - '.' || write(1, cell_pointer, 1),
```

this simply will subtract '.' from the current symbol if they're equal the
difference is 0 and the right hand side of the logical or will be executed,
otherwise it will be something different than 0, true, and because of short 
circuiting the right hand side won't be executed.

The most difficult part of the interpreter is loop handling, this is done by
recursively calling main when we encounter a '['

```c
cur_symbol - '[' || (main(*cell_pointer, &program_counter - 1), 
    program_counter = *cell_pointer ? program_counter - 1 : loop_end))
```

as you can see we call `main` with the first argument being the value of the
cell we're currently pointing at, if it is 0 the code inside the loop won't be
executed, and the direction of the program counter subtracting one to get the
right pointer when we do

```c
char *program_counter = program[1];
```

at the beginning of main. When we return from our main recursion we have to
set the program counter depending of the value of the current cell, if it is 
not zero we go back to the beginning of the loop, that is we set the program 
counter to itself minus one, to account for the increment done in the for 
condition, otherwise we continue execution by setting the program counter to
the end of the loop. 

We set the value of the loop end when returning from main

```c
loop_end = program_counter;
```

since all pointers have the same size we can assign a char pointer to an
int one, even if the compiler yells at us.
