; intel2gas ps347277.asm > b.asm; clang -c -nostdlib -o b.o b.asm

extern copy_to_clipboard

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
    
    push esi
    push edi
    push ebx

    jmp compression

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
    mov ebx, [ebp + 12]
    mov eax, [ebx]
    push eax

    mov ecx, [ebp + 8]
    push ecx

    ; call copy_to_clipboard

    add esp, 8

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
    xor edx, edx; idea
    xor esi, esi; i
    xor edi, edi; occurences

.compression_loop:
    xor edi, edi
    mov eax, [ebp + 12]
    cmp esi, [eax]
    jge .compression_end

    xor ecx, ecx
    mov eax, [ebp + 8]
    mov cl, [eax + esi]

    mov [eax + edx], cl
    add edx, 1
    
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

    push esi
    mov esi, edx
    xor edx, edx
    push edx

.pushing_number_on_stack:
    cmp edi, 0
    je .pushing_number_return

    xor eax, eax
    xor edx, edx
    mov eax, edi
    mov bx, 10
    div bx

    add edx, 48
    mov edi, eax

    push edx

    jmp .pushing_number_on_stack

.pushing_number_return:
    mov eax, [ebp + 8]
    pop edx
    cmp edx, 0
    je .pushing_number_return_restore
    mov [eax + esi], dl
    add esi, 1
    jmp .pushing_number_return

.pushing_number_return_restore:
    mov edx, esi
    pop esi
    jmp .compression_loop
    
.compression_end:
    mov eax, [ebp + 12]
    cmp [eax], edx
    je .compression_returning
    mov [eax], edx
    mov eax, [ebp + 8]
    mov byte [eax + edx], 0

.compression_returning:
    jmp copy_safely.end
