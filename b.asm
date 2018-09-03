# intel2gas ps347277.asm > b.asm; clang -c -nostdlib -o b.o b.asm

.global copy_safely

# eax - zmienne
# esi - i
# edi - j
# ebx - offset

copy_safely: 
    pushl %ebp
    movl %esp,%ebp

    # and  esp, 0xfffffff0

    pushl %esi
    pushl %edi
    pushl %ebx

copy_safely.copy_safely_cipher: 
    movl $0,%esi
    movl $0,%edi

copy_safely.check_if_buffer_len: 
    movl 12(%ebp),%eax
    movl (%eax),%eax     # eax holds *buffer_len

    cmpl %eax,%esi       # i < (*buffer_len)
    jl copy_safely.cipher_loop

copy_safely.epilogue: 
    movl 12(%ebp),%eax
    movl (%eax),%eax

    popl %ebx
    popl %edi
    popl %edi

    movl %ebp,%esp
    popl %ebp
    ret

copy_safely.cipher_loop: 
    movl $0,%ebx        # offset = 0

copy_safely.key_offset: 
    movb 16(%ebp),%al
    movb (%eax,%edi),%al # key[j]

    cmpb $57,%al        #  key[j] <= '9'
    jg copy_safely.key_uppercase_check

copy_safely.key_numerical_loop: 
    jmp copy_safely.epilogue
    movl $10,%ecx
copy_safely.key_numerical_check_length: 
    movl 20(%ebp),%eax
    cmpl %eax,%edi
    je copy_safely.key_epilogue
copy_safely.key_numerical_is_still_numeric: 
    movb 16(%ebp),%al
    movb (%eax,%edi),%al # key[j]

    cmpb $57,%al        #  key[j] <= '9'
    jg copy_safely.key_epilogue
copy_safely.key_multiply_offset_by_10: 
    cmpl $0,%ecx
    je copy_safely.key_add_offset
    addl %ebx,%ebx
    subl $1,%ecx
    jmp copy_safely.key_multiply_offset_by_10
copy_safely.key_add_offset: 
    xorl %eax,%eax
    movb (%eax,%edi),%al
    subb $48,%al
    addl %eax,%ebx # offset = 10*offset + key[j] - '0';
    addl $1,%edi
    jmp copy_safely.key_numerical_loop

copy_safely.key_uppercase_check: 
    cmpb $90,%al
    jg copy_safely.key_lowercase_check
    jmp copy_safely.epilogue

    movl %eax,%ebx
    subl $65,%ebx         # offset = key[j] - 'A';
    addl $1,%edi          # j += 1

    jmp copy_safely.key_epilogue

copy_safely.key_lowercase_check: 
    movl %eax,%ebx
    subl $97,%edx
    addl $1,%edi
    jmp copy_safely.epilogue

copy_safely.key_epilogue: 
    movl 20(%ebp),%eax
    cmpl %eax,%edi
    jne copy_safely.buffer_offset
    subl %eax,%edi

copy_safely.buffer_offset: 
    movb 4(%ebp),%al
    movb (%eax,%esi),%al # buffer[i]
    cmpl $90,%eax
    jg copy_safely.buffer_lowercase

    subl $65,%eax
    addl %eax,%ebx       # offset += buffer[i] - 'A';

    jmp copy_safely.offset_normalize

copy_safely.buffer_lowercase: 
    subl $97,%eax
    addl %eax,%ebx       # offset += buffer[i] - 'a';

copy_safely.offset_normalize:    # offset %= 26
    cmpl $26,%ebx
    jl copy_safely.apply_offset
    subl $26,%ebx
    jmp copy_safely.offset_normalize

copy_safely.apply_offset: 
    xorl %eax,%eax
    movb 4(%ebp),%al
    movb (%eax,%esi),%al # buffer[i]
    cmpl $90,%eax
    jg copy_safely.apply_offset_lowercase
    addl $65,%ebx
    movl %ebx,(%eax,%esi) # buffer[i] = 'A' + offset;
    jmp copy_safely.apply_offset_epilogue

copy_safely.apply_offset_lowercase: 
    addl $97,%ebx
    movl %ebx,(%eax,%esi) # buffer[i] = 'a' + offset;
    jmp copy_safely.apply_offset_epilogue

copy_safely.apply_offset_epilogue: 
    addl $1,%esi
    jmp copy_safely.check_if_buffer_len

