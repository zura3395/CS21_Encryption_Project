;
;Include our external functions library functions
%include "./functions64.inc"

SECTION .data
	openPrompt	db	"Welcome to my Program", 0h
	closePrompt	db	"Program ending, have a nice day", 0h
	
	noArgumentsErrorMsg	db	"Error: No arguments were passed to the program.", 0h
		.sizeof equ	$-noArgumentsErrorMsg
		
	noSecondArgumentErrorMsg	db	"Error: A second argument was not passed to the program.", 0h
		.sizeof equ	$-noSecondArgumentErrorMsg
	
	threeArgumentsErrorMsg	db	"Error: More than two arguments were passed to the program.", 0h
		.sizeof equ	$-threeArgumentsErrorMsg
	
	inputOpenErrorMsg	db	"Error: Input file could not be opened.", 0h
		.sizeof	equ	$-inputOpenErrorMsg
		
	outputOpenErrorMsg	db	"Error: Output file could not be opened.", 0h
		.sizeof	equ	$-outputOpenErrorMsg
		
	memoryErrorMsg	db	"Error: Dynamic memory allocation/deallocation failed.", 0h
		.sizeof equ $-memoryErrorMsg
	
	keyPrompt	db	"Please enter an encryption key: ", 0h
		.sizeof	equ	$-keyPrompt
		
	blankKeyMsg	db	"Error: Key cannot be blank.", 0h
		.sizeof	equ	$-blankKeyMsg
		
	fileCopyMsg	db	"Source file will be copied to destination file.", 0h
		.sizeof equ $-fileCopyMsg
		
	endl		db	0ah, 0dh, 0h
		.sizeof	equ	$-endl
		
	bytesWritten	dq	0
	
	bytesWrittenMsg	db	" bytes written.", 0h
		.sizeof	equ	$-bytesWrittenMsg

SECTION .bss
	inputFilePath	resb	255
	
	outputFilePath	resb	255

	inputFileDescriptor		resq	1
	
	outputFileDescriptor	resq	1
		
	KEY			resb	255
		.sizeof	equ	$-KEY
	keyLength	resb	1
		
	originalLimit	resq	1			;Contains the original 'bottom' of program
	newLimit		resq	1			;Contains the new 'bottom of program

SECTION     .text
	global      _start

_start:
	nop
	
    push	openPrompt
    call	PrintString
    call	Printendl
    
    mov		rdi, [rsp+16]			;Check if first argument exists
    cmp		rdi, 0					;Does it?
    je		noArguments				;If not, jump to no arguments error message
    
    mov		rdi, [rsp+24]			;Check if a second argument exists
    cmp		rdi, 0					;Does it?
    je		noSecondArgument		;If not, jump to no second arugment error message
    
    mov		rdi, [rsp+32]			;Check if a third argument exists
    cmp		rdi, 0					;Does it?
    jne		threeArguments			;If yes, jump to three arguments error message
    
    mov		rdi, [rsp+16]			;Get input file path
    mov		[inputFilePath], rdi	;Store in input file name string
    
    mov		rdi, [rsp+24]			;Get output file path
    mov		[outputFilePath], rdi	;Store in input file name string
    
    mov		rax, 2						;Open the file for read
    mov		rdi, [inputFilePath]		;Address of our file name string
    mov		rsi, 0						;Read access only
    mov		rdx, 0						;Read access only
    syscall								;Poke the kernel
    cmp		rax, 0						;If rax is less than 0, error opening the file
    jl		inputOpenError				;Display an error
    mov		[inputFileDescriptor], rax	;Store file descriptor
    
    mov		rax, 85						;Create and open file
    mov		rdi, [outputFilePath]		;Address of our file name string
    mov		rsi, 664o					;File permissions
    syscall								;Poke the kernel
    cmp		rax, 0						;If rax is less than 0, error opening the file
    jl		outputOpenError				;Display an error
    mov		[outputFileDescriptor], rax	;Store file descriptor

    ;Tell user the source file is being copied to the destination file
    push	fileCopyMsg
    push	fileCopyMsg.sizeof
    call	outputDisplay
    
    push	endl
	push	endl.sizeof
	call	outputDisplay
    
    ;Prompt user for key
    push	keyPrompt
    push	keyPrompt.sizeof
    call	outputDisplay
    
    ;User input time
    push	KEY
    push	KEY.sizeof
    call	inputKeyboard
    dec		rax
    cmp		rax, 0
    jle		blankKey
    mov		[keyLength], rax
    
    ;Find the 'bottom' of program
    mov		rax, 0ch				;sys_brk
    mov		rdi, 0h					;Get current memory address
    syscall							;Poke the kernel
    mov		[originalLimit], rax	;Save the original 'bottom' of my code
    
    ;Increase the address of the bottom of program by 0ffffh bytes
    add		rax, 0ffffh			;Add 0ffffh bytes
    
    ;Allocate the 0ffffh bytes
    mov		rdi, rax					;Memory address with the 0ffffh bytes
    syscall								;Poke the kernel
    cmp		rax, QWORD [originalLimit]	;Did allocation work?
    je		memoryError					;Nope, so memory error
    mov		[newLimit], rax				;Save the new 'bottom' of my code
    
    readLoop:
		;Read to input file to memory
		mov		rax, 0						;Read from input file
		mov		rdi, [inputFileDescriptor]	;File descriptor
		mov		rsi, newLimit				;Memory buffer address to read the data into
		mov		rdx, 0ffffh					;Memory buffer size
		syscall
		
		add		QWORD [bytesWritten], rax	;Store bytes read
		mov		r12, rax					;Store bytes read
		cmp		rax, 0						;If end of file, stop reading
		je		exitRead					;Jump to exit read loop
		
		push	newLimit
		push	rax
		push	KEY
		push	keyLength
		call	EncryptMe
		
		;Write to output file from memory
		mov		rax, 1						;Write data
		mov		rdi, [outputFileDescriptor]	;File descriptor
		mov		rsi, newLimit				;The address of what we wish to write
		mov		rdx, r12					;The number of bytes to write
		syscall								;Poke the kernel
		
		jmp		readLoop					;Keep reading until data read is less than 0ffffh
    
    exitRead:
    ;Delete the previously allocated memory
    mov		rax, 0ch					;sys_brk
    mov		rdi, [originalLimit]		;Original 'bottom'
    syscall
    cmp		rax, QWORD [originalLimit]	;Did the deallocation work?
    jne		memoryError					;Nope, so memory error
    
    mov		rax, 3						;Close the file
    mov		rdi, [inputFileDescriptor]	;File descriptor to close
    
    mov		rax, 3						;Close the file
    mov		rdi, [outputFileDescriptor]	;File descriptor to close
    
    
    push	QWORD [bytesWritten]
    call	Print64bitNumDecimal
    
    push	bytesWrittenMsg
    push	bytesWrittenMsg.sizeof
    call	outputDisplay
    
    push	endl
    push	endl.sizeof
    call	outputDisplay
    
    jmp		endProgram
    
	noArguments:
		push	noArgumentsErrorMsg
		push	noArgumentsErrorMsg.sizeof
		call	outputDisplay
		
		push	endl
		push	endl.sizeof
		call	outputDisplay
		jmp		endProgram
		
	noSecondArgument:
		push	noSecondArgumentErrorMsg
		push	noSecondArgumentErrorMsg.sizeof
		call	outputDisplay
		
		push	endl
		push	endl.sizeof
		call	outputDisplay
		jmp		endProgram
     
    threeArguments:
		push	threeArgumentsErrorMsg
		push	threeArgumentsErrorMsg.sizeof
		call	outputDisplay
		
		push	endl
		push	endl.sizeof
		call	outputDisplay
		jmp		endProgram
    
    inputOpenError:
		push	inputOpenErrorMsg
		push	inputOpenErrorMsg.sizeof
		call	outputDisplay
		
		push	endl
		push	endl.sizeof
		call	outputDisplay
	    
	    jmp		endProgram
	    
    outputOpenError:
		push	outputOpenErrorMsg
		push	outputOpenErrorMsg.sizeof
		call	outputDisplay
		
		push	endl
		push	endl.sizeof
		call	outputDisplay
		
		jmp		endProgram
	
	blankKey:
		push	blankKeyMsg
		push	blankKeyMsg.sizeof
		call	outputDisplay
		
		push	endl
		push	endl.sizeof
		call	outputDisplay
		
		jmp		endProgram
	
	memoryError:
		push	memoryErrorMsg
		push	memoryErrorMsg.sizeof
		call	outputDisplay
		
		push	endl
		push	endl.sizeof
		call	outputDisplay
		
		jmp		endProgram
		
	endProgram:
    push	closePrompt			;The prompt address - argument #1
    call  	PrintString
    call  	Printendl
    
    nop
;
;Setup the registers for exit and poke the kernel
;Exit: 
Exit:
	mov		rax, 60					;60 = system exit
	mov		rdi, 0					;0 = return code
	syscall							;Poke the kernel

;inputKeyboard
;Inputs:	rbp+24 - Buffer address
;			rbp+16 - Buffer length
inputKeyboard:
	;Backup registers
	push	rbp			;Save caller's rbp value
	mov		rbp, rsp	;Setup new rbp to be the same as the top of the stack
	push	rsi
	push	rdx
	push	rdi

	mov	rsi, [rbp+24]	;Buffer address
	mov	rdx, [rbp+16]	;Buffer length
	mov	rax, 00h		;Read
	mov	rdi, 00h		;stdin
	syscall				;Poke the kernel
	
	pop		rdi			;Restore registers
	pop		rdx
	pop		rsi
	
	;Destroy stack frame
	mov		rsp, rbp	;Restore rsp to what it was before the function
	pop		rbp			;Restore the caller's rbp value
ret 16


;outputDisplay
;Inputs:	rbp+24 - String address
;			rbp+16 - String length
outputDisplay:
	;Backup registers
	push	rbp			;Save caller's rbp value
	mov		rbp, rsp	;Setup new rbp to be the same as the top of the stack
	push	rsi
	push	rdx
	push	rax
	push	rdi

	mov	rsi, [rbp+24]	;String address
	mov	rdx, [rbp+16]	;String length
	mov	rax, 01h		;Write to console
	mov	rdi, 01h		;stdout
	syscall				;Poke the kernel
	
	pop		rdi			;Restore registers
	pop		rax
	pop		rdx
	pop		rsi
	
	;Destroy stack frame
	mov		rsp, rbp	;Restore rsp to what it was before the function
	pop		rbp			;Restore the caller's rbp value
ret 16

;EncryptMe
;Inputs:	rbp+40 - Address to allocated memory
;			rbp+32 - Length of allocated memory
;			rbp+24 - Address to encryption/decryption key
;			rbp+16 - Length of encryption key
EncryptMe:
	;Backup registers
	push	rbp			;Save caller's rbp value
	mov		rbp, rsp	;Setup new rbp to be the same as the top of the stack
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	r8
	push	r10
	push	rsi
	
	mov		rbx, [rbp+40]	;Put memory address into rbx
	mov		rcx, [rbp+32]	;Put length of allocated memory into rcx
	mov		rdx, [rbp+24]	;Put key into rdx
	mov		r8, 0h			;Set offset to zero
	mov		rsi, [rbp+16]	;Move the value
	movzx	r10, BYTE [rsi]
		
	encryptionLoop:
		mov al, [rdx+r8]					;Load character from key
		xor BYTE [rbx], al					;Encrypt
		inc rbx								;Go to the next location in the memory address
		inc r8								;Go to the next location in the key
		cmp	r8, r10							;Check if key offset is past the length of the key
		jb	skipEncryption					;If false, skip
		mov r8, 0							;If true, reset key offset
		skipEncryption:
			nop
	loop encryptionLoop						;Loop
	
	pop		rsi
	pop		r10
	pop		r9
	pop		r8
	pop		rdx
	pop		rcx
	pop		rbx
	pop		rax
	
	;Destroy stack frame
	mov		rsp, rbp	;Restore rsp to what it was before the function
	pop		rbp			;Restore the caller's rbp value
ret 32
