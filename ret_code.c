// intel2gas ps347277.asm > b.asm; clang -c -nostdlib -o b.o b.asm; clang b.o ret_code.c -o test
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

uint32_t copy_safely(char *buffer, uint32_t *buffer_len, const char *key, uint32_t key_len);

int main() {
    char buffer1[] = "abCzX";
    uint32_t buffer1_len = strlen(buffer1);

    char key1[] = "dE35";
    uint32_t key1_len = strlen(key1);

    int r = copy_safely(buffer1, &buffer1_len, key1, key1_len);

    printf("%d: %s\n", r, buffer1);
}