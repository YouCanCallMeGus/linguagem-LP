#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "codegen.h"
#include <unistd.h>
#define DEBUG_MSG(msg) do { \
    fprintf(stderr, "🔥 CODEGEN DEBUG: %s (file: %s, line: %d)\n", msg, __FILE__, __LINE__); \
    fflush(stderr); \
} while(0)

#define MAX_VARS 100
#define MAX_STACK 100
#define SCALE 10  

struct CodeGenerator {
    FILE* output;
    int label_counter;
    int var_counter;
    char* vars[MAX_VARS];
    int var_addrs[MAX_VARS];
    int while_start_stack[MAX_STACK];
    int while_end_stack[MAX_STACK];
    int while_top;
    int for_start_stack[MAX_STACK];
    int for_end_stack[MAX_STACK];
    int for_varaddr_stack[MAX_STACK];
    int for_top;
};

static int is_number(const char* s) {
    if (!s || !*s) return 0;
    const char* p = s;
    if (*p == '+' || *p == '-') p++;
    int has_digit = 0;
    int has_dot = 0;
    while (*p) {
        if (isdigit((unsigned char)*p)) { has_digit = 1; }
        else if (*p == '.' && !has_dot) { has_dot = 1; }
        else return 0;
        p++;
    }
    return has_digit;
}

static long scale_number(const char* s) {
    if (!is_number(s)) return 0;
    double v = atof(s);
    return (long)(v * SCALE + 0.5);
}

CodeGenerator* codegen_init(const char* output_file) {
    CodeGenerator* cg = malloc(sizeof(CodeGenerator));
    if (!cg) return NULL;
    cg->output = fopen(output_file, "w");
    if (!cg->output) { free(cg); return NULL; }

    cg->label_counter = 0;
    cg->var_counter = 0;
    for (int i = 0; i < MAX_VARS; ++i) {
        cg->vars[i] = NULL;
        cg->var_addrs[i] = 10 + i;
    }
    cg->while_top = 0;
    cg->for_top = 0;

    fprintf(cg->output, "; === PROGRAMA COMPILADO DE LMD ===\n");
    fprintf(cg->output, "INICIAR\n");
    fprintf(cg->output, "SET VELOCIDADE 0\n");
    fprintf(cg->output, "SET TEMPO 0\n");
    fprintf(cg->output, "SET INCLINACAO 0\n");
    fprintf(cg->output, "SET R1 0\n");
    fprintf(cg->output, "SET R2 0\n\n");

    return cg;
}

void codegen_free(CodeGenerator* cg) {
    if (!cg) return;
    for (int i = 0; i < cg->var_counter; ++i) if (cg->vars[i]) free(cg->vars[i]);
    if (cg->output) fclose(cg->output);
    free(cg);
}

void codegen_comment(CodeGenerator* cg, const char* comment) {
    fprintf(cg->output, "; %s\n", comment);
}

int codegen_get_var_addr(CodeGenerator* cg, const char* var_name) {
    if (!var_name) return 0;
    for (int i = 0; i < cg->var_counter; ++i)
        if (cg->vars[i] && strcmp(cg->vars[i], var_name) == 0) return cg->var_addrs[i];
    if (cg->var_counter >= MAX_VARS) { fprintf(stderr,"ERRO: limite de variaveis\n"); exit(1); }
    cg->vars[cg->var_counter] = strdup(var_name);
    int addr = cg->var_addrs[cg->var_counter];
    cg->var_counter++;
    return addr;
}

void codegen_compile_expression(CodeGenerator* cg, const char* expr, const char* target_reg) {
    if (!expr || !*expr) { 
        fprintf(cg->output, "SET %s 0\n", target_reg); 
        return; 
    }

    if (is_number(expr)) {
        long v = scale_number(expr);
        fprintf(cg->output, "SET %s %ld\n", target_reg, v);
        return;
    }

    if (strcmp(expr, "tempo") == 0) {
        fprintf(cg->output, "READSENSOR %s tempo\n", target_reg);
        return;
    }
    if (strcmp(expr, "velocidade") == 0) {
        fprintf(cg->output, "READSENSOR %s velocidade\n", target_reg);
        return;
    }
    if (strcmp(expr, "inclinacao") == 0) {
        fprintf(cg->output, "READSENSOR %s inclinacao\n", target_reg);
        return;
    }

    int addr = codegen_get_var_addr(cg, expr);
    if (addr > 0) {
        fprintf(cg->output, "LOAD %s %d\n", target_reg, addr);
        return;
    }

    fprintf(cg->output, "SET %s 0\n", target_reg);
}

void codegen_declare_var(CodeGenerator* cg, const char* var_name, const char* expr) {
    fprintf(cg->output, "; existe %s sendo %s\n", var_name, expr);
    int addr = codegen_get_var_addr(cg, var_name);
    codegen_compile_expression(cg, expr, "R1");
    fprintf(cg->output, "STORE R1 %d\n\n", addr);
}

void codegen_set_velocidade(CodeGenerator* cg, const char* expr) {
    fprintf(cg->output, "; velocidade recebe %s\n", expr);
    codegen_compile_expression(cg, expr, "R1");
    fprintf(cg->output, "SET VELOCIDADE R1\n\n");
}

void codegen_set_inclinacao(CodeGenerator* cg, const char* expr) {
    fprintf(cg->output, "; inclinacao recebe %s\n", expr);
    codegen_compile_expression(cg, expr, "R1");
    fprintf(cg->output, "SET INCLINACAO R1\n\n");
}

void codegen_set_tempo(CodeGenerator* cg, const char* expr) {
    fprintf(cg->output, "; tempo recebe %s\n", expr);
    codegen_compile_expression(cg, expr, "R1");
    fprintf(cg->output, "SET TEMPO R1\n\n");
}

void codegen_assign_var(CodeGenerator* cg, const char* var_name, const char* expr) {
    fprintf(cg->output, "; %s recebe %s\n", var_name, expr);
    
    if (strcmp(var_name, "velocidade") == 0) {
        codegen_compile_arithmetic(cg, expr, "R1");
        fprintf(cg->output, "SET VELOCIDADE R1\n\n");  
        return;
    }
    else if (strcmp(var_name, "inclinacao") == 0) {
        codegen_compile_arithmetic(cg, expr, "R1");
        fprintf(cg->output, "SET INCLINACAO R1\n\n");  
        return;
    }
    else if (strcmp(var_name, "tempo") == 0) {
        codegen_compile_arithmetic(cg, expr, "R1");
        fprintf(cg->output, "SET TEMPO R1\n\n");  
        return;
    }
    
    int addr = codegen_get_var_addr(cg, var_name);
    codegen_compile_arithmetic(cg, expr, "R1");
    fprintf(cg->output, "STORE R1 %d\n\n", addr);  
}

void codegen_if_condition(CodeGenerator* cg, const char* condition) {
    int else_label = cg->label_counter++;
    int end_label = cg->label_counter++;
    
    fprintf(cg->output, "; se %s ->ent\n", condition);
    
    if (strstr(condition, ">")) {
        char cond_copy[256];
        strncpy(cond_copy, condition, 255);
        char* left = strtok(cond_copy, ">");
        char* right = strtok(NULL, ">");
        
        if (left && right) {
            while (*left == ' ') left++;
            while (*right == ' ') right++;
            
            codegen_compile_expression(cg, left, "R1");
            codegen_compile_expression(cg, right, "R2");
            fprintf(cg->output, "JL if_end_%d\n", else_label);
        }
    }
    
    fprintf(cg->output, "GOTO if_fim_%d\n", end_label);
    fprintf(cg->output, "if_end_%d:\n", else_label);
    fprintf(cg->output, "if_fim_%d:\n\n", end_label);
}

void codegen_while_start(CodeGenerator* cg, const char* condition) {
    if (cg->while_top >= MAX_STACK) { 
        fprintf(stderr,"ERRO: while stack overflow\n"); 
        exit(1); 
    }
    
    int start_label = cg->label_counter++;
    int end_label = cg->label_counter++;
    cg->while_start_stack[cg->while_top] = start_label;
    cg->while_end_stack[cg->while_top] = end_label;
    cg->while_top++;

    fprintf(cg->output, "; dadoQue (%s)\n", condition);
    fprintf(cg->output, "while_test_%d:\n", start_label);

    char cond_copy[256];
    strncpy(cond_copy, condition, 255);
    cond_copy[255] = '\0';

    char* left = cond_copy;
    char* right = NULL;
    char* op = NULL;

    if ((op = strstr(cond_copy, "<"))) {
        *op = '\0';
        right = op + 1;
    } else if ((op = strstr(cond_copy, ">"))) {
        *op = '\0';
        right = op + 1;
    }

    if (left && right) {
        while (*left == ' ') left++;
        while (*right == ' ') right++;

        codegen_compile_expression(cg, left, "R1");
        codegen_compile_expression(cg, right, "R2");

        if (strstr(condition, "<")) {
            fprintf(cg->output, "JG while_end_%d\n", end_label);  
        } else if (strstr(condition, ">")) {
            fprintf(cg->output, "JL while_end_%d\n", end_label);  
        }
    }
    
    fprintf(cg->output, "\n");
}

void codegen_while_end(CodeGenerator* cg) {
    if (cg->while_top <= 0) { 
        fprintf(stderr,"ERRO: while_end sem start\n"); 
        exit(1); 
    }
    
    cg->while_top--;
    int start_label = cg->while_start_stack[cg->while_top];
    int end_label = cg->while_end_stack[cg->while_top];
    
    fprintf(cg->output, "GOTO while_test_%d\n", start_label);
    fprintf(cg->output, "while_end_%d:\n\n", end_label);
}

void codegen_for_start(CodeGenerator* cg, const char* var, const char* start, const char* end, const char* step) {
    if (cg->for_top >= MAX_STACK) { 
        fprintf(stderr,"ERRO: for stack overflow\n"); 
        exit(1); 
    }
    
    int var_addr = codegen_get_var_addr(cg, var);
    int start_label = cg->label_counter++;
    int end_label = cg->label_counter++;

    codegen_compile_expression(cg, start, "R1");
    fprintf(cg->output, "STORE R1 %d\n", var_addr);

    cg->for_start_stack[cg->for_top] = start_label;
    cg->for_end_stack[cg->for_top] = end_label;
    cg->for_varaddr_stack[cg->for_top] = var_addr;
    cg->for_top++;

    fprintf(cg->output, "; paraTodo %s de %s ate %s passo %s\n", var, start, end, step);
    fprintf(cg->output, "for_test_%d:\n", start_label);
    
    fprintf(cg->output, "LOAD R1 %d\n", var_addr);
    codegen_compile_expression(cg, end, "R2");
    fprintf(cg->output, "JG for_end_%d\n\n", end_label);
}

void codegen_for_end(CodeGenerator* cg) {
    if (cg->for_top <= 0) { 
        fprintf(stderr,"ERRO: for_end sem start\n"); 
        exit(1); 
    }
    
    cg->for_top--;
    int start_label = cg->for_start_stack[cg->for_top];
    int end_label = cg->for_end_stack[cg->for_top];
    int var_addr = cg->for_varaddr_stack[cg->for_top];

    fprintf(cg->output, "LOAD R1 %d\n", var_addr);
    fprintf(cg->output, "SET R2 10\n"); 
    fprintf(cg->output, "ADD R1 R2\n");
    fprintf(cg->output, "STORE R1 %d\n", var_addr);

    fprintf(cg->output, "GOTO for_test_%d\n", start_label);
    fprintf(cg->output, "for_end_%d:\n\n", end_label);
}

void codegen_halt(CodeGenerator* cg) {
    fprintf(cg->output, "\n; === FIM DO PROGRAMA ===\n");
    fprintf(cg->output, "STATUS\n");
    fprintf(cg->output, "HALT\n");
}

void codegen_compile_arithmetic(CodeGenerator* cg, const char* expr, const char* target_reg) {
    DEBUG_MSG("codegen_compile_arithmetic CHAMADA!");
    
    fprintf(cg->output, "; 🔥 COMPILANDO: %s\n", expr);
    
    char expr_copy[256];
    strncpy(expr_copy, expr, 255);
    expr_copy[255] = '\0';
    
    char* p = expr_copy;
    while (*p == ' ') p++;
    char* end = expr_copy + strlen(expr_copy) - 1;
    while (end > p && *end == ' ') end--;
    *(end + 1) = '\0';
    
    char* plus = strchr(p, '+');
    if (plus) {
        *plus = '\0';
        char* left = p;
        char* right = plus + 1;
        
        while (*left == ' ') left++;
        while (*right == ' ') right++;
        
        compile_operand(cg, left, target_reg);
        compile_operand(cg, right, "R2");
        
        fprintf(cg->output, "ADD %s R2\n", target_reg);
        return;
    }
    
    compile_operand(cg, p, target_reg);
}

void compile_operand(CodeGenerator* cg, const char* operand, const char* target_reg) {
    if (is_number(operand)) {
        long val = scale_number(operand);
        fprintf(cg->output, "SET %s %ld\n", target_reg, val);
        return;
    }
    
    if (strcmp(operand, "velocidade") == 0) {
        fprintf(cg->output, "READSENSOR %s velocidade\n", target_reg);
        return;
    }
    if (strcmp(operand, "tempo") == 0) {
        fprintf(cg->output, "READSENSOR %s tempo\n", target_reg);
        return;
    }
    if (strcmp(operand, "inclinacao") == 0 || strcmp(operand, "inclinacao") == 0) {
        fprintf(cg->output, "READSENSOR %s inclinacao\n", target_reg);
        return;
    }
    
    int addr = codegen_get_var_addr(cg, operand);
    if (addr > 0) {
        fprintf(cg->output, "LOAD %s %d\n", target_reg, addr);
        return;
    }
    
    fprintf(cg->output, "SET %s 0\n", target_reg);
}

void codegen_debug_vars(CodeGenerator* cg) {
    fprintf(cg->output, "; DEBUG: Variáveis: ");
    for (int i = 0; i < cg->var_counter; ++i) {
        if (cg->vars[i]) {
            fprintf(cg->output, "%s@%d ", cg->vars[i], cg->var_addrs[i]);
        }
    }
    fprintf(cg->output, "\n");
}