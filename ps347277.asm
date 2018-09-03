; intel2gas ps347277.asm > b.asm; clang -c -nostdlib -o b.o b.asm

global copy_safely
global compression
global epilogue

; eax - zmienne
; esi - i
; edi - j
; ebx - offset

copy_safely:
    push ebp
    mov ebp, esp
    
    ; and  esp, 0xfffffff0
    
    push esi
    push edi
    push ebx

    jmp .epilogue

.copy_safely_cipher:
    mov esi, 0
    mov edi, 0

.check_if_buffer_len:
    mov eax, [ebp + 12]
    mov eax, [eax]       ; eax holds *buffer_len

    cmp esi, eax         ; i < (*buffer_len)
    jl .cipher_loop

.epilogue:
    nop
    jmp compression

.end:
    pop ebx
    pop edi
    pop edi

    mov esp, ebp
    pop ebp
    ret
    
.cipher_loop:
    mov ebx, 0          ; offset = 0

.key_offset:
    xor eax, eax
    mov edx, [ebp + 16]
    mov al, [edx + edi]  ; key[j]

    cmp eax, 57          ;  key[j] <= '9'
    jg .key_uppercase_check
    
.key_numerical_loop:
    mov ecx, 10
.key_numerical_check_length:
    mov eax, [ebp + 20]
    cmp edi, eax
    je .key_epilogue
.key_numerical_is_still_numeric:
    xor eax, eax
    mov edx, [ebp + 16]
    mov al, [edx + edi]  ; key[j]
    cmp eax, 57          ;  key[j] <= '9'
    jg .key_epilogue

.key_multiply_offset_by_10:
    cmp ecx, 0
    je .key_add_offset
    add ebx, ebx
    sub ecx, 1
    jmp .key_multiply_offset_by_10
.key_add_offset:
    xor eax, eax
    mov edx, [ebp + 16]
    mov al, [edx + edi]
    sub eax, 48
    add ebx, eax ; offset = 10*offset + key[j] - '0';
    add edi, 1
    jmp .key_numerical_loop

.key_uppercase_check:
    cmp eax, 90
    jg .key_lowercase_check

    mov ebx, eax
    sub ebx, 65           ; offset = key[j] - 'A';
    add edi, 1            ; j += 1
    
    jmp .key_epilogue

.key_lowercase_check:
    mov ebx, eax
    sub ebx, 97
    add edi, 1

.key_epilogue:
    mov eax, [ebp + 20]
    cmp edi, eax
    jne .buffer_offset
    sub edi, eax

.buffer_offset:
    xor eax, eax
    mov edx, [ebp + 8]
    mov al, [edx + esi]  ; buffer[i]
    cmp eax, 90
    jg .buffer_lowercase

    sub eax, 65    
    add ebx, eax         ; offset += buffer[i] - 'A';

    jmp .offset_normalize

.buffer_lowercase:
    sub eax, 97
    add ebx, eax         ; offset += buffer[i] - 'a';

.offset_normalize:              ; offset %= 26
    cmp ebx, 26
    jl .apply_offset
    sub ebx, 26
    jmp .offset_normalize
    
.apply_offset:
    xor eax, eax
    mov edx, [ebp + 8]
    mov al, [edx + esi]  ; buffer[i]
    cmp al, 90
    jg .apply_offset_lowercase
    add ebx, 65
    mov [edx+esi], bl    ; buffer[i] = 'A' + offset;
    jmp .apply_offset_epilogue

.apply_offset_lowercase:
    add ebx, 97
    add eax, esi
    mov [edx+esi], bl    ; buffer[i] = 'a' + offset;
    jmp .apply_offset_epilogue

.apply_offset_epilogue:
    add esi, 1
    jmp .check_if_buffer_len

compression:
    xor eax, eax
    xor ebx, ebx
    xor ecx, ecx; c
    xor edx, edx;
    xor esi, esi; i
    xor edi, edi; occurences

    push eax       ; STACK GUARD

.compression_loop:
    xor edi, edi; occurences = 0
    mov eax, [ebp + 12]
    cmp esi, [eax]
    jge .compression_epilogue

    xor ecx, ecx
    mov eax, [ebp + 8]
    mov cl, [eax + esi]

    push ecx      ; save char on stack

.occurences_loop:
    mov eax, [ebp + 8]
    cmp cl, [eax + esi]
    jne .occurences_loop_break
    add edi, 1     ; occurences++
    add esi, 1     ; i++
    jmp .occurences_loop

.occurences_loop_break:
    cmp edi, 1
    jle .compression_loop

.pushing_number_on_stack:
    cmp edi, 0
    je .occurences_loop

    xor eax, eax
    xor edx, edx
    mov eax, edi
    mov bx, 10
    div bx

    add edx, 48
    push edx

    mov edi, eax
    jmp .pushing_number_on_stack

.compression_epilogue:
    xor edi, edi

.epilogue_loop:
    pop ebx
    cmp ebx, 0
    je .compression_end

    mov eax, [ebp + 8]
    mov [eax + edi], bl
    add edi, 1
    jmp .epilogue_loop
    

.compression_end:
    mov byte [eax + edi], 0
    mov eax, [ebp + 12]
    mov [eax], edi
    ; jmp copy_safely.end

.reverse_string:
    sub edi, 1
    xor esi, esi
.revere_string_loop:
    cmp esi, edi
    jge copy_safely.end

    mov eax, [ebp + 8]
    xor ebx, ebx
    mov bl, [eax + edi]

    xor ecx, ecx
    mov cl, [eax + esi]

    mov [eax + esi], bl
    mov [eax + edi], cl

    add esi, 1
    sub edi, 1

    jmp .revere_string_loop

