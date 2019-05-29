.386
.model flat, stdcall

includelib msvcrt.lib

extern exit: proc
extern scanf: proc
extern printf: proc
extern fscanf: proc
extern fprintf: proc
extern fopen: proc
extern fclose: proc
extern strcmp: proc
extern putchar: proc

public start
.data

;========================================Typedefs
integer			typedef 	sdword
char 			typedef 	byte

;========================================Structure declarations
node DQ 0

first 			DQ	 		0							;nodeT* first=NULL
last 			DQ	 		0							;nodeT*  last=NULL
new_node 		DQ 			0							;folosit temporar in functii pentru copierea node-urilor
														

str_array 		DD 			128 dup(0)					;Array of type NODE- uninitialized	
														;sizeof str_array=4*128
														
;========================================Strings declarations
arrow 			char 		13, 10, "> ", 0
new_line 		char 		13, 10, 0
format_cmd 		char 		"%s", 0
format_insert 	char 		32, "%d", 0
format_sterge 	char 		32, "%d", 0
format_file 	char 		32, "%s", 0
format_afis		char		"%d ", 0
format_file_r	char		"%d ", 0
creare_lista 	char 		"creare", 0
afisare 		char 		"afisare", 0
iesire 			char		"exit", 0
insert 			char		"insert", 0
sterge 			char 		"delete", 0
save 			char 		"save", 0
load 			char 		"load", 0

;========================================Messages
msg_del			char		186, "Lista a fost stearsa. Creati o lista noua sau", 13, 10, 186, "folositi comanda load!", 13, 10, 0
msg_crt			char		186, "Lista a fost creata!", 9,  "-->	first=last=NULL", 13, 10, 0
msg_print		char		186, "Lista este: ",9, 0
msg_print_file	char		"Lista este: ",9, 0
msg_file		char		"Introduceti numele fisierului: ",9, 0
msg_insert		char		186, "Numarul %d a fost inserat in lista!", 13, 10, 0 
msg_cmd_er		char		186, "Comanda introdusa nu exista!", 13, 10, 0
start_msg_up	char		201, 61 dup(205), 187, " ", 13, 10, 0
start_msg		char 		186, "Introduceti una dintre urmatoarele comenzi pentru a continua:", 13, 10, 186, 9, "1. creare- pentru a crea lista", 13, 10, 186, 9, "2. afisare- pentru a afisa lista", 13, 10, 186, 9, "3. exit- pentru a inchide programul", 13, 10, 186, 9, "4. insert <nr>- pentru a insera un numar", 13, 10, 186, 9, "5. delete <index>- pentru a sterge dupa index", 13, 10, 186, 9, "6. save- pentru a salva lista intr-un fisier", 13, 10, 186, 9, "7. load- pentru a incarca lista dintr-un fisier", 13, 10, 0
start_msg_dw	char		200, 61 dup(205), 188, " ", 13, 10, 0
exit_msg		char		186, "Lista a fost stearsa. Programul se inchide..........", 13, 10, 0
msg_dindex		char 		186, "Nodul cu index %d a fost sters!", 13, 10, 0
msg_file_er		char		186, "Fisierul nu a putut fi deschis!", 13, 10, 0

;========================================File operations
mode_write		char		"w", 0
mode_read		char 		"r", 0

;========================================Others
ver 			dword 		1
nr_elem 		dword 		0
index			dword		0
cmd 			char 		30 dup(0)
nr 				integer 	?
file_name 		char 		130 dup(0)
testare			char 		186, "Mesaj pentru test!", 13, 10, 186, "key= %d", 9, "old_key= %d", 13, 10, 0
buffer			dword		0

.code

;=================================================MAIN

;=============================Creare
;Used to initialize first and last pointers with NULL;
;nr_elem used for the key array is set to 0
_creare proc
	push EBP
	mov EBP, ESP
	
	mov dword ptr[first], 0				;first=last=NULL
	mov dword ptr[first+4], 0
	mov dword ptr[last], 0
	mov dword ptr[last+4], 0
	mov nr_elem, 0						;Set the initial number of elements to 0
	push offset msg_crt					;Insert "Lista a fost creata" message
	call printf
	add ESP, 4
	
	mov ESP, EBP
	pop EBP
	ret
_creare endp

;=============================Insert
;The basic insert function. A new node is created, the integer stored in ESI, is moved in the first dword from
;the qword sized node and NULL(0) in the second dword- used for next pointer. 
_insert proc
	push EBP
	mov EBP, ESP
	
	mov ESI, nr
	
	mov EAX, dword ptr[last]							
	mov EBX, dword ptr[last+4]							
	
	mov dword ptr[new_node], ESI						;new_node->key=nr
	mov ECX, dword ptr[new_node]						
	mov dword ptr[new_node+4], 0						;new_node->next=NULL
	mov EDX, dword ptr[new_node+4]	
	
	cmp dword ptr[first], EAX							;
	jne ins_last										; if(first==last==NULL)
	cmp dword ptr[first+4], EBX							;
	jne ins_last										;
	
	ins_first:		mov dword ptr[first], ECX			;first=NULL
					mov dword ptr[first+4], 0
					mov dword ptr[last], ECX			;last=NULL
					mov dword ptr[last+4], 0
					jmp proc_end
					
	ins_last:		lea EAX, [new_node] 
					mov dword ptr[last+4], EAX			;last.next=&new_node
					mov dword ptr[last], ECX
					mov dword ptr[last+4], EDX
	
	proc_end:		;push EAX							;Uncomment for line by line testing
					;push dword ptr[last]
					;push offset testare
					;call printf
					;add esp, 12
					
					mov EDI, nr							;The new key is stored in an dword array 
					mov ESI, nr_elem					;used for printing the list
					mov str_array[ESI], EDI
					add nr_elem, 4						;nr_elem is increased with the size of the array element
					mov ESP, EBP
					pop EBP
					ret
					
_insert endp

;=============================Print
;Procedure used for printing the list. If it is empty '0' will be printed, alongside a
;message. Else the elements will be printed in the order of the nodes containing them
_afisare proc
	push EBP
	mov EBP, ESP
	
	push offset msg_print						;"Lista este:\t"
	call printf
	add ESP, 4
	mov ECX, nr_elem							;Used for the loop
	mov ESI, 0
	cmp ECX, 0									;If the list in empty, '0' will be printed
	je empty_list
	while_loop:		push ECX
					push str_array[ESI]			;Print the keys in the order they were inserted
					push offset format_afis
					call printf
					add ESP, 8
					add ESI, 4					;Used for index. Is increased with the size of dword
					pop ECX
					sub ECX, 3					;It removes the additional '0's from the empty spaces
					loop while_loop				;DONT TOUCHA MY SPACODE!!!!!!
					jmp end_proc				;IT IZ GUD
					
	empty_list:		push ECX					;If the list is empty print '0'
					push offset format_afis
					call printf
					add ESP, 8
					
	end_proc:		push offset new_line
					call printf
					add ESP, 4
					mov ESP, EBP
					pop EBP
					ret
_afisare endp

;=============================Save in file
;Used to save the list in the file inserted in console. The procedure then calls the _del_all proc 
;to remove the elements from the list. 
_save proc
	push EBP
	mov EBP, ESP
	
	push offset mode_write						;fopen in read mode
	push offset file_name
	call fopen
	add ESP, 8
	mov buffer, EAX								;file stream 
	
	push offset msg_del							;The function was deleted 
	call printf
	add ESP, 4
	
	push offset msg_print_file					;Prints the content of the list is
	push buffer									;the inserted file
	call fprintf
	add ESP, 8
	mov ECX, nr_elem							;Used for the loop
	mov ESI, 0									;Used as index
	cmp ECX, 0									;If the list is empty, '0' is printed in the file
	je empty_list_s
	
	while_loop_s:	push ECX					;Scrierea din array-ul de key-uri
					push str_array[ESI]
					push offset format_afis	
					push buffer
					call fprintf
					add ESP, 12
					add ESI, 4					;Add the size of dword to the array index
					pop ECX
					sub ECX, 3					;For removing the additional '0's 
					loop while_loop_s
					jmp end_proc				;Jump over the empty list case
					
	empty_list_s:	push ECX					;Daca lista este goala, scrie '0'
					push offset format_afis
					push buffer
					call fprintf
					add ESP, 12
					
	end_proc:		push buffer					;Inchiderea fisierului
					call fclose
					add ESP, 4
					mov ESP, EBP
					pop EBP
					ret
_save endp

;=============================Load from file
;Used for loading the integers from a file, then it inserts them in the list.
_load proc
	push EBP
	mov EBP, ESP
	
	push offset mode_read								;Deschiderea in mod read
	push offset file_name
	call fopen
	add ESP, 8
	
	mov buffer, EAX										;fopen returns the buffer address in EAX
	test EAX, EAX										;If the file wasn't opened correctly
	jnz file_ok											;it printf a warning message then jumps
	push offset msg_cmd_er								;to the very end of the procedure
	call printf
	add ESP, 4
	jmp proc_end2
	
	file_ok:		call _del_all						;The list needs to be empty 
					call _creare						;The list needs to be created
					
	while_file:		push offset nr						;Used for reading the integer from file
					push offset format_file_r
					push buffer
					call fscanf
					add ESP, 12
					
					test EAX, EAX						;If EAX is negative, usually '-1'
					js proc_end1						;the program reached EOF
					
					;push nr							;Used for line by line testing
					;push offset format_afis			;Uncomment for testing
					;call printf
					;add esp, 8
					
					call _insert						;Call the _insert function for creating nodes
					jmp while_file 
					
	proc_end1:		push buffer							;It closes the file 
					call fclose
					add ESP, 4
	proc_end2:		mov ESP, EBP
					pop EBP
					ret
_load endp

;=============================Delete list
;Deletes all the elements from the list.
_del_all proc
	push EBP
	mov EBP, ESP
	
	mov ECX, nr_elem									;Sterg elementele din lista
	mov ESI, 0
	cmp ECX, 0
	je empty_list
	while_loop:		push ECX
					mov str_array[ESI], 0				;It deletes the keys from the array
					add ESI, 4
					pop ECX
					sub ECX, 3
					loop while_loop
					
					mov nr_elem, 0						;After the loop is over, the first element will be inserted
														;at index 0
	empty_list:		mov ESP, EBP
					pop EBP
					ret
_del_all endp

start:
	push offset start_msg_up							;Intro message
	call printf
	add ESP, 4
	push offset start_msg
	call printf
	add ESP, 4
	push offset start_msg_dw
	call printf
	add ESP, 4
	while_ver:		push offset arrow
					call printf
					add ESP, 4
					push offset cmd						;Used for storing the command
					push offset format_cmd
					call scanf
					add ESP, 8
					
;========================================Recunoastere comanda
					push offset cmd						;strcmp(cmd, creare_lista)
					push offset creare_lista
					call strcmp
					add ESP, 8
					cmp EAX, 0
					jz call_creare						;Jumps to the call procedure line
					
					push offset cmd						;strcmp(cmd, afisare)
					push offset afisare
					call strcmp
					add ESP, 8
					cmp EAX, 0
					jz call_afisare						;Jumps to the call procedure line
					
					push offset cmd						;strcmp(cmd, insert)
					push offset insert
					call strcmp
					add ESP, 8
					cmp EAX, 0	
					jz call_insert						;Jumps to the call procedure line
					
					push offset cmd						;strcmp(cmd, sterge)
					push offset sterge
					call strcmp
					add ESP, 8
					cmp EAX, 0
					jz call_delete_i					;Jumps to the call procedure line
					
					push offset cmd						;strcmp(cmd, save)
					push offset save
					call strcmp
					add ESP, 8
					cmp EAX, 0
					jz call_save						;Jumps to the call procedure line
					
					push offset cmd						;strcmp(cmd, load)
					push offset load
					call strcmp
					add ESP, 8
					cmp EAX, 0
					jz call_load						;Jumps to the call procedure line
					
					push offset cmd						;strcmp(cmd, iesire)
					push offset iesire
					call strcmp
					add ESP, 8
					cmp EAX, 0
					jz call_exit						;Jumps to the call procedure line
					
					push offset msg_cmd_er				;If the command doesn't exists, it 
					call printf							;printf an error message
					add ESP, 4
					jmp while_ver						;Reads another command
					
;========================================Apelare comanda				
	call_creare:	call _creare
					jmp while_ver
					
	call_afisare:	call _afisare
					jmp while_ver
					
	call_insert:	push offset nr
					push offset format_insert			;Used for reading the integer
					call scanf
					add esp, 8
					mov EDX, nr
					push nr
					push offset msg_insert
					call printf
					add ESP, 8
					
					call _insert
					jmp while_ver
					
	call_delete_i:	push offset index
					push offset format_insert
					call scanf
					add esp, 8
					mov EAX, index
					push EAX
					push offset msg_dindex
					call printf
					add ESP, 8
					call _del_all					
					jmp while_ver
					
	call_load:		mov buffer, 0
					push offset file_name				;It reads the name of the file
					push offset format_file
					call scanf
					add ESP, 8
					
					call _load
					jmp while_ver
					
	call_save:		mov buffer, 0
					push offset file_name
					push offset format_file				;It reads the name of the file
					call scanf
					add ESP, 8
					
					call _save	
					call _del_all
					jmp while_ver
					
	call_exit:		call _del_all
					push offset exit_msg
					call printf
					add ESP, 4
					push 0
					call exit
				
end start
