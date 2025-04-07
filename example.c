#include <stdio.h>
#include <stdlib.h>

// Global variables
int global_var1 = 100;
int global_var2 = 200;

// Function that should be stripped
void function_to_strip() {
    printf("This function should be stripped.\n");
}

// Function that should be kept
void function_to_keep() {
    printf("This function should remain.\n");
}

// Another function that should be stripped
void another_function_to_strip() {
    printf("Another function to be stripped.\n");
}

int main() {
    printf("global_var1 = %d, global_var2 = %d\n", global_var1, global_var2);
    function_to_strip();
    function_to_keep();
    another_function_to_strip();
    return 0;
}
