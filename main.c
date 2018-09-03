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

    copy_safely(buffer1, &buffer1_len, key1, key1_len);

    char buffer2[] = "zzmoZ";
    uint32_t buffer2_len = strlen(buffer2);
    char key2[] = "12ab";
    uint32_t key2_len = strlen(key2);

    copy_safely(buffer2, &buffer2_len, key2, key2_len);
}

uint32_t copy_safely(char *buffer, uint32_t *buffer_len, const char *key, uint32_t key_len) {
    uint32_t i = 0;
    uint32_t j = 0;
    uint32_t offset;

    while (i < (*buffer_len)) {
        offset = 0;
        // key
        if (key[j] <= '9') {
            while (j < key_len && key[j] <= '9') {
                offset = 10 * offset;
                offset += key[j] - '0';
                j = j + 1;
            }
        }
        else if (key[j] <= 'Z') {
            offset = key[j] - 'A';
            j += 1;
        }
        else {
            offset = key[j] - 'a';
            j += 1;
        }

        if (j == key_len) {
            j = 0;
        }

        if (buffer[i] <= 'Z') {
            offset += buffer[i] - 'A';
        } else {
            offset += buffer[i] - 'a';
        }

        while (offset >= 26) {
            offset -= 26;
        }

        if (offset >= 26) {
            offset = offset - 26;
        }

        if (buffer[i] <= 'Z') {
            buffer[i] = 'A' + offset;
        }
        else {
            buffer[i] = 'a' + offset;
        }

        i += 1;
    }

    printf("%s\n", buffer);

    return 0;
}