global long_mode_start

section .text
bits 64
long_mode_start:
    ; Blank out the screen
    mov edi, 0xB8000
    mov rcx, 500                      ; Since we are clearing uint64_t over here, we put the count as Count/4.
    mov rax, 0x0F20F200F200F20       ; Set the value to set the screen to: black background, white foreground, blank spaces.
    rep stosq                         ; Clear the entire screen. 

    ; call the rust main
    extern rust_main
    call rust_main

.clear_screen

.os_returned:
    ; rust main returned, print `OS returned!`
    mov rax, 0x4f724f204f534f4f
    mov [0xb8000], rax
    mov rax, 0x4f724f754f744f65
    mov [0xb8008], rax
    mov rax, 0x4f214f644f654f6e
    mov [0xb8010], rax
    ;print `OKAY` to screen
    mov rax, 0x2f592f412f4b2f4f
    mov qword [0xb80A0], rax
    hlt
