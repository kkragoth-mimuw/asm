; intel2gas ps347277.asm > b.asm; clang -c -nostdlib -o b.o b.asm

global copy_safely

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

.copy_safely_cipher:
    mov esi, 0
    mov edi, 0

.check_if_buffer_len:
    mov eax, [ebp + 12]
    mov eax, [eax]       ; eax holds *buffer_len

    cmp esi, eax         ; i < (*buffer_len)
    jl .cipher_loop

.epilogue:
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
    mov byte al, [edx + edi]  ; key[j]

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
    mov byte al, [edx + edi]  ; key[j]
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
    mov byte al, [edx + edi]
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
    mov byte al, [edx + esi]  ; buffer[i]
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
    mov byte al, [edx + esi]  ; buffer[i]
    cmp al, 90
    jg .apply_offset_lowercase
    add ebx, 65
    mov byte [edx+esi], bl    ; buffer[i] = 'A' + offset;
    jmp .apply_offset_epilogue

.apply_offset_lowercase:
    add ebx, 97
    add eax, esi
    mov byte [edx+esi], bl    ; buffer[i] = 'a' + offset;
    jmp .apply_offset_epilogue

.apply_offset_epilogue:
    add esi, 1
    jmp .check_if_buffer_len
