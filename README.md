# toy-compiler

Example input:
```
read i;
if i>0 then start
	j:=1;
	while i>1 do start
		j:=j*i;
		i:=i-1;
	end;
	print j;
end;
```

Corresponding output:
```
0 READ 			# read a value from the console
1 POP $0 		# save the value off the top of the stack under variable $0
# if statement
2 PUSH $0
3 PUSH 0
4 SUB
5 JLZ $23 		# jump to the end of the program if the condition is not met
6 PUSH 1
7 POP $1
# beginning of while loop
8 PUSH $0
9 PUSH 1
10 SUB
11 JLEZ $21 	# if loop condition is false - jump to the end of the loop
12 PUSH $1
13 PUSH $0
14 MUL
15 POP $1
16 PUSH $0
17 PUSH 1
18 SUB
19 POP $0
20 JMP $8 		# jump to beginning of the loop
# end of while loop
21 PUSH $1
22 PRINT		# print the value on top of the stack (in this case $1)
23 STOP
```
