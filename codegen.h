#ifndef CODEGEN_H
#define CODEGEN_H

typedef struct CodeGenerator CodeGenerator;

CodeGenerator* codegen_init(const char* output_file);
void codegen_free(CodeGenerator* cg);

void codegen_comment(CodeGenerator* cg, const char* comment);
void codegen_declare_var(CodeGenerator* cg, const char* var_name, const char* expr);
void codegen_set_velocidade(CodeGenerator* cg, const char* expr);
void codegen_set_inclinacao(CodeGenerator* cg, const char* expr);
void codegen_set_tempo(CodeGenerator* cg, const char* expr);
void codegen_assign_var(CodeGenerator* cg, const char* var_name, const char* expr);
void codegen_if_condition(CodeGenerator* cg, const char* condition); 
void codegen_while_start(CodeGenerator* cg, const char* condition);
void codegen_while_end(CodeGenerator* cg);
void codegen_for_start(CodeGenerator* cg, const char* var, const char* start, const char* end, const char* step);
void codegen_for_end(CodeGenerator* cg);
void codegen_halt(CodeGenerator* cg);
void codegen_debug_vars(CodeGenerator* cg);
void codegen_compile_expression(CodeGenerator* cg, const char* expr, const char* target_reg);
void codegen_compile_arithmetic(CodeGenerator* cg, const char* expr, const char* target_reg);
void compile_operand(CodeGenerator* cg, const char* operand, const char* target_reg);

#endif