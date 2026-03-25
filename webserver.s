.intel_syntax noprefix
.global _start

.section .data
msg: .ascii "HTTP/1.0 200 OK\r\n\r\n"

.section .text
_start:
mov rax, 41
mov rdi, 2
mov rsi, 1
mov rdx, 0
syscall

mov r12, rdi

mov rdi, rax
sub rsp, 16
mov word ptr [rsp], 2
mov word ptr [rsp+2], 0x5000
mov dword ptr [rsp+4], 0
mov qword ptr [rsp+8], 0
mov rsi, rsp
mov rdx, 16
mov rax, 49
syscall

mov rsi, 0
mov rax, 50
syscall

loop:
mov rax, 43
mov rdi, 3
xor rsi, rsi
mov rdx, 0
syscall

cmp rax, -1
je done

mov rax, 57
syscall

cmp rax, 0
jne closeparent

mov rax, 3
mov rdi, 3
syscall


mov rdi, 4
sub rsp, 1024
lea rsi, [rsp]
mov rdx, 1024
mov rax, 0
syscall

cmp dword ptr [rsp], 0x54534F50
je postreq

mov byte ptr [rsp+20], 0x00
lea rdi, [rsp+4]
mov rsi, 0
mov rdx, 15
mov rax, 2
syscall

mov rdi, 3
sub rsp, 1024
lea rsi, [rsp]
mov rdx, 1024
mov rax,0
syscall
push rax

mov rax, 3
mov rdi, 3
syscall

mov rdi, 4
lea rsi, [msg]
mov rdx, 19
mov rax,1
syscall

mov rax, 1
mov rdi, 4
lea rsi, [rsp+8]
pop rdx
syscall

mov rax, 3
syscall
jmp done

postreq:
mov rbx, rax
lea rdi, [rsp+5]
mov rcx,5
oloop:
mov al, [rsp+rcx]
cmp al, ' '
je opennn
inc rcx
jmp oloop
opennn:
mov byte ptr [rsp+rcx], 0x0
mov rdx, 0777
mov rsi, 65
mov rax, 2
syscall

mov rcx, rbx
wloop:
mov al, [rsp+rcx]
cmp al, '\n'
je wwrite
dec rcx
jmp wloop
wwrite:
sub rcx, rbx
neg rcx
dec rcx
mov rdi, 3
mov rdx, rcx
add rsp, rbx
sub rsp, rcx
lea rsi, [rsp]
mov rax, 1
syscall

mov rax, 3
mov rdi, 3
syscall

mov rdi,4
lea rsi, [msg]
mov rdx, 19
mov rax, 1
syscall

done:
mov rax, 60
mov rdi, 0
syscall

closeparent:
mov rax, 3
mov rdi, 4
syscall
jmp loop

