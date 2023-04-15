#include <assert.h>
#include <inttypes.h>
#include <pthread.h>
#include <stddef.h>


#include <stdio.h>
#include <stdlib.h>

// Define the structure for a stack node
struct Node {
    int data;
    struct Node* next;
};

// Define the structure for a stack
struct Stack {
    struct Node* top;
};

// Function to create a new node
struct Node* newNode(int data) {
    struct Node* node = (struct Node*)malloc(sizeof(struct Node));
    node->data = data;
    node->next = NULL;
    return node;
}

// Function to check if the stack is empty
int isEmpty(struct Stack* stack) {
    return stack->top == NULL;
}

// Function to push an element onto the stack
void push(struct Stack* stack, int data) {
    struct Node* node = newNode(data);
    node->next = stack->top;
    stack->top = node;
}

// Function to pop an element from the stack
int pop(struct Stack* stack) {
    if (isEmpty(stack)) {
        printf("Error: Stack is empty.\n");
        return -1;
    }
    struct Node* temp = stack->top;
    int data = temp->data;
    stack->top = temp->next;
    free(temp);
    return data;
}

// Function to get the top element of the stack
int top(struct Stack* stack) {
    if (isEmpty(stack)) {
        printf("Error: Stack is empty.\n");
        return -1;
    }
    return stack->top->data;
}

int main() {
    struct Stack* stack = (struct Stack*)malloc(sizeof(struct Stack));
    stack->top = NULL;
    push(stack, 10);
    push(stack, 20);
    push(stack, 30);
    printf("Top element of stack: %d\n", top(stack));
    printf("Popped element: %d\n", pop(stack));
    printf("Top element of stack: %d\n", top(stack));
    return 0;
}


void plus(uint64_t n, struct Stack* stc ){
    int x = pop(stc);
    int y = pop(stc);
    push(stc, x + y);
}


void mult(uint64_t n, struct Stack* stc ){
    int x = pop(stc);
    int y = pop(stc);
    push(stc, x * y);
}

void mins(uint64_t n, struct Stack* stc ){
    int x = pop(stc);
    int y = pop(stc);
    push(stc, x - y);
}

void addNr(uint64_t n, struct Stack* stc, char c ){
    push(stc, atoi(&c));
}
void addCoreNr(uint64_t n, struct Stack* stc){
    push(stc, n);
}


// Tę funkcję woła rdzeń.ange files in vim
uint64_t get_value(uint64_t n); 

// Tę funkcję woła rdzeń.
void put_value(uint64_t n, uint64_t v);

// To jest deklaracja funkcji, którą trzeba zaimplementować.
uint64_t core(uint64_t n, char const *p){
    struct Stack* stc = (struct Stack*)malloc(sizeof(struct Stack));
    stc->top = NULL;

    while(*p != 0){
        if(*p == '+')plus(n, stc);
        if(*p == '*')mult(n, stc);
        if(*p == '+')mins(n, stc);

        if( '0'<= *p && *p <='9')addNr(n, stc, *p);
        if(*p == 'n')addCoreNr(n, stc);

        if(*p == 'B')loop(n.)
    }
}

