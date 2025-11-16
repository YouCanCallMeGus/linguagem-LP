from dataclasses import dataclass
from typing import List, Dict, Tuple, Optional, Any
import random

Register = str

@dataclass
class Instr:
    op: str
    args: Tuple[str, ...]

class EsteiraVM:
    """
    VM Turing-completa para controle de esteira com:
    - 3 registradores principais + 2 registradores de uso geral
    - Memória (pilha + RAM)
    - Sensores readonly
    - Instruções para Turing-completude
    """

    def __init__(self):
        # Registradores principais
        self.registers: Dict[Register, int] = {
            "VELOCIDADE": 0, 
            "TEMPO": 0, 
            "INCLINACAO": 0,
            "R1": 0,  # Registrador de uso geral 1
            "R2": 0,  # Registrador de uso geral 2
            "SP": 0,  # Stack Pointer
        }
        
        # Memória 
        self.ram: List[int] = [0] * 256  # 256 palavras de RAM
        self.stack: List[int] = []
        
        # Programa e controle
        self.program: List[Instr] = []
        self.labels: Dict[str, int] = {}
        self.pc: int = 0
        self.halted: bool = False
        self.steps: int = 0
        
        # Estado físico e sensores (readonly)
        self.running: bool = False
        self.elapsed_time: int = 0
        self.sensors = {
            "tempo": lambda: self.elapsed_time,
            "velocidade": lambda: self.registers["VELOCIDADE"],
            "inclinacao": lambda: self.registers["INCLINACAO"], 
            "peso": lambda: random.randint(50, 100),
            "temperatura": lambda: random.randint(20, 35),
            "tensao": lambda: random.randint(220, 240),
        }

    def get_value(self, operand: str) -> int:
        """Obtém valor de um operando (registrador ou constante)"""
        if operand in self.registers:
            return self.registers[operand]
        elif operand.isdigit() or (operand[0] == '-' and operand[1:].isdigit()):
            return int(operand)
        else:
            raise ValueError(f"Operando inválido: {operand}")

    def set_value(self, target: str, value: int):
        """Define valor para um registrador"""
        if target in self.registers:
            self.registers[target] = value
        else:
            raise ValueError(f"Registrador inválido: {target}")

    def load_program(self, source: str):
        """Carrega programa assembly da esteira"""
        self.program.clear()
        self.labels.clear()
        self.stack.clear()
        self.pc = 0
        self.halted = False
        self.steps = 0
        self.elapsed_time = 0
        
        for reg in self.registers:
            self.registers[reg] = 0

        lines = source.splitlines()
        
        idx = 0
        for raw in lines:
            line = raw.split(';', 1)[0].strip()
            if not line:
                continue
            if line.endswith(':'):
                label = line[:-1].strip()
                if label in self.labels:
                    raise ValueError(f"Label duplicado: {label}")
                self.labels[label] = idx
            else:
                idx += 1

        for raw in lines:
            line = raw.split(';', 1)[0].strip()
            if not line or line.endswith(':'):
                continue
                
            tokens = line.replace(',', ' ').split()
            op = tokens[0].upper()
            args = tuple(tokens[1:])
            
            self.validate_instruction(op, args, line)
            self.program.append(Instr(op, args))

    def validate_instruction(self, op: str, args: Tuple[str, ...], line: str):
        """Valida instruções"""
        valid_instructions = {
            "INICIAR": 0, "PARAR": 0, "STATUS": 0, "HALT": 0,
            "SET": 2, "INC": 1, "DEC": 1, "ADD": 2, "SUB": 2, "MUL": 2, "DIV": 2,
            "GOTO": 1, "DECJZ": 2, "CALL": 1, "RET": 0,
            "PUSH": 1, "POP": 1, "LOAD": 2, "STORE": 2,
            "CMP": 2, "JZ": 1, "JNZ": 1, "JL": 1, "JG": 1,
            "AND": 2, "OR": 2, "NOT": 1, "XOR": 2,
            "READSENSOR": 2,
        }
        
        if op not in valid_instructions:
            raise ValueError(f"Instrução desconhecida: {op}")
            
        expected_args = valid_instructions[op]
        if len(args) != expected_args:
            raise ValueError(f"{op} espera {expected_args} argumentos: {line}")

    def step(self):
        """Executa uma instrução"""
        if self.halted:
            return
            
        if self.pc >= len(self.program):
            self.halted = True
            return

        instr = self.program[self.pc]
        self.steps += 1

        op, args = instr.op, instr.args
        
        try:
            # === CONTROLE DE FLUXO (TURING-COMPLETUDE) ===
            if op == "GOTO":
                self.goto(args[0])
            elif op == "DECJZ":
                self.decjz(args[0], args[1])
            elif op == "CALL":
                self.call(args[0])
            elif op == "RET":
                self.ret()
            elif op == "JZ":
                if self.registers["R1"] == 0:
                    self.goto(args[0])
                else:
                    self.pc += 1
            elif op == "JNZ":
                if self.registers["R1"] != 0:
                    self.goto(args[0])
                else:
                    self.pc += 1
            elif op == "JL":
                if self.registers["R1"] < self.registers["R2"]:
                    self.goto(args[0])
                else:
                    self.pc += 1
            elif op == "JG":
                if self.registers["R1"] > self.registers["R2"]:
                    self.goto(args[0])
                else:
                    self.pc += 1
            
            # === ARITMÉTICAS ===
            elif op == "SET":
                self.set(args[0], args[1])
            elif op == "INC":
                self.inc(args[0])
            elif op == "DEC":
                self.dec(args[0])
            elif op == "ADD":
                self.add(args[0], args[1])
            elif op == "SUB":
                self.sub(args[0], args[1])
            elif op == "MUL":
                self.mul(args[0], args[1])
            elif op == "DIV":
                self.div(args[0], args[1])
            
            # === MEMÓRIA ===
            elif op == "PUSH":
                self.push(args[0])
            elif op == "POP":
                self.pop(args[0])
            elif op == "LOAD":
                self.load(args[0], args[1])
            elif op == "STORE":
                self.store(args[0], args[1])
            
            # === LÓGICAS ===
            elif op == "AND":
                self.and_op(args[0], args[1])
            elif op == "OR":
                self.or_op(args[0], args[1])
            elif op == "NOT":
                self.not_op(args[0])
            elif op == "XOR":
                self.xor_op(args[0], args[1])
            elif op == "CMP":
                self.cmp(args[0], args[1])
            
            # === SENSORES ===
            elif op == "READSENSOR":
                self.read_sensor(args[0], args[1])
            
            # === CONTROLE DE ESTEIRA ===
            elif op == "INICIAR":
                self.running = True
                print("🏃 Esteira INICIADA")
                self.pc += 1
            elif op == "PARAR":
                self.running = False
                print("🛑 Esteira PARADA")
                self.pc += 1
            elif op == "STATUS":
                self.print_status()
                self.pc += 1
            elif op == "HALT":
                self.running = False
                self.halted = True
                print("⏹️ Programa FINALIZADO")
            
            else:
                raise ValueError(f"Instrução não implementada: {op}")
                
        except Exception as e:
            raise RuntimeError(f"Erro na instrução {op} {args} (PC={self.pc}): {e}")

        if self.running:
            self.elapsed_time += 1

    
    def goto(self, label: str):
        """GOTO label - Salto incondicional"""
        if label not in self.labels:
            raise ValueError(f"Label não encontrado: {label}")
        self.pc = self.labels[label]

    def decjz(self, reg: str, label: str):
        """DECJZ reg, label - Decrementa e salta se zero"""
        if reg not in self.registers:
            raise ValueError(f"Registrador inválido: {reg}")
            
        if self.registers[reg] == 0:
            if label not in self.labels:
                raise ValueError(f"Label não encontrado: {label}")
            self.pc = self.labels[label]
        else:
            self.registers[reg] -= 1
            self.pc += 1

    def call(self, label: str):
        """CALL label - Chama subrotina"""
        if label not in self.labels:
            raise ValueError(f"Label não encontrado: {label}")
        self.stack.append(self.pc + 1)
        self.pc = self.labels[label]

    def ret(self):
        """RET - Retorna de subrotina"""
        if not self.stack:
            raise ValueError("Stack underflow")
        self.pc = self.stack.pop()

    def set(self, reg: str, value: str):
        """SET reg, value"""
        if reg not in self.registers:
            raise ValueError(f"Registrador inválido: {reg}")
        self.registers[reg] = self.get_value(value)
        self.pc += 1

    def inc(self, reg: str):
        """INC reg"""
        if reg not in self.registers:
            raise ValueError(f"Registrador inválido: {reg}")
        self.registers[reg] += 1
        self.pc += 1

    def dec(self, reg: str):
        """DEC reg"""
        if reg not in self.registers:
            raise ValueError(f"Registrador inválido: {reg}")
        self.registers[reg] = max(0, self.registers[reg] - 1)
        self.pc += 1

    def add(self, reg1: str, reg2: str):
        """ADD reg1, reg2 - reg1 = reg1 + reg2"""
        if reg1 not in self.registers:
            raise ValueError(f"Registrador inválido: {reg1}")
        self.registers[reg1] += self.get_value(reg2)
        self.pc += 1

    def sub(self, reg1: str, reg2: str):
        """SUB reg1, reg2 - reg1 = reg1 - reg2"""
        if reg1 not in self.registers:
            raise ValueError(f"Registrador inválido: {reg1}")
        self.registers[reg1] -= self.get_value(reg2)
        self.pc += 1

    def mul(self, reg1: str, reg2: str):
        """MUL reg1, reg2 - reg1 = reg1 * reg2"""
        if reg1 not in self.registers:
            raise ValueError(f"Registrador inválido: {reg1}")
        self.registers[reg1] *= self.get_value(reg2)
        self.pc += 1

    def div(self, reg1: str, reg2: str):
        """DIV reg1, reg2 - reg1 = reg1 / reg2 (divisão inteira)"""
        if reg1 not in self.registers:
            raise ValueError(f"Registrador inválido: {reg1}")
        divisor = self.get_value(reg2)
        if divisor == 0:
            raise ValueError("Divisão por zero")
        self.registers[reg1] //= divisor
        self.pc += 1

    def push(self, reg: str):
        """PUSH reg - Empilha valor"""
        self.stack.append(self.get_value(reg))
        self.pc += 1

    def pop(self, reg: str):
        """POP reg - Desempilha para registrador"""
        if not self.stack:
            raise ValueError("Stack underflow")
        self.set_value(reg, self.stack.pop())
        self.pc += 1

    def load(self, reg: str, addr: str):
        """LOAD reg, addr - Carrega da RAM"""
        if reg not in self.registers:
            raise ValueError(f"Registrador inválido: {reg}")
        address = self.get_value(addr)
        self.registers[reg] = self.ram[address % len(self.ram)]
        self.pc += 1

    def store(self, reg: str, addr: str):
        """STORE reg, addr - Armazena na RAM"""
        address = self.get_value(addr)
        value = self.get_value(reg)
        self.ram[address % len(self.ram)] = value
        self.pc += 1

    def and_op(self, reg1: str, reg2: str):
        """AND reg1, reg2 - reg1 = reg1 AND reg2"""
        if reg1 not in self.registers:
            raise ValueError(f"Registrador inválido: {reg1}")
        self.registers[reg1] = self.registers[reg1] & self.get_value(reg2)
        self.pc += 1

    def or_op(self, reg1: str, reg2: str):
        """OR reg1, reg2 - reg1 = reg1 OR reg2"""
        if reg1 not in self.registers:
            raise ValueError(f"Registrador inválido: {reg1}")
        self.registers[reg1] = self.registers[reg1] | self.get_value(reg2)
        self.pc += 1

    def not_op(self, reg: str):
        """NOT reg - reg = NOT reg"""
        if reg not in self.registers:
            raise ValueError(f"Registrador inválido: {reg}")
        self.registers[reg] = ~self.registers[reg] & 0xFFFF  
        self.pc += 1

    def xor_op(self, reg1: str, reg2: str):
        """XOR reg1, reg2 - reg1 = reg1 XOR reg2"""
        if reg1 not in self.registers:
            raise ValueError(f"Registrador inválido: {reg1}")
        self.registers[reg1] = self.registers[reg1] ^ self.get_value(reg2)
        self.pc += 1

    def cmp(self, reg1: str, reg2: str):
        """CMP reg1, reg2 - Compara e seta flags (em R1)"""
        val1 = self.get_value(reg1)
        val2 = self.get_value(reg2)
        result = val1 - val2
        self.registers["R1"] = 0  
        if result == 0:
            self.registers["R1"] = 0  
        elif result < 0:
            self.registers["R1"] = -1 
        else:
            self.registers["R1"] = 1  
        self.pc += 1

    def read_sensor(self, reg: str, sensor: str):
        """READSENSOR reg, sensor - Lê sensor para registrador"""
        if reg not in self.registers:
            raise ValueError(f"Registrador inválido: {reg}")
        sensor_name = sensor.lower()
        if sensor_name in self.sensors:
            self.registers[reg] = self.sensors[sensor_name]()
        else:
            raise ValueError(f"Sensor não encontrado: {sensor}")
        self.pc += 1

    def print_status(self):
        """Mostra status atual da esteira"""
        status = "✅ LIGADA" if self.running else "❌ PARADA"
        print(f"\n--- STATUS ESTEIRA ---")
        print(f"Estado: {status}")
        print(f"Velocidade: {self.registers['VELOCIDADE']/10} km/h")
        print(f"Tempo: {self.registers['TEMPO']/10} segundos")
        print(f"Inclinação: {self.registers['INCLINACAO']/10}°")
        print(f"R1: {self.registers['R1']}, R2: {self.registers['R2']}")
        print(f"Stack: {len(self.stack)} items")
        print(f"RAM: {self.ram[:16]}...")
        print(f"Sensores: peso={self.sensors['peso']()}, temp={self.sensors['temperatura']()}")
        print(f"Tempo decorrido: {self.elapsed_time}s")
        print(f"Próxima instrução: {self.pc}")
        print("----------------------\n")

    def run(self, max_steps: Optional[int] = 1000):
        """Executa o programa"""
        print("🚀 Iniciando execução da EsteiraVM...")
        while not self.halted:
            if max_steps and self.steps >= max_steps:
                raise RuntimeError(f"Limite de {max_steps} steps atingido!")
            self.step()

    def get_state(self) -> Dict:
        """Retorna estado completo da VM"""
        return {
            "registers": dict(self.registers),
            "running": self.running,
            "elapsed_time": self.elapsed_time,
            "pc": self.pc,
            "halted": self.halted,
            "steps": self.steps,
            "stack": list(self.stack),
            "ram": list(self.ram)
        }

simple_factorial =  """
; Fatorial de 5 usando apenas operações confiáveis
INICIAR
SET R1 6      
SET R2 1       

loop:
    DECJZ R1 end_loop
    
    SET TEMPO R2    
    SET INCLINACAO R1  
    
    mul_loop:
        DECJZ INCLINACAO end_mul
        ADD R2 TEMPO
        GOTO mul_loop
    
    end_mul:
    GOTO loop

end_loop:
STORE R2 0
STATUS
HALT
"""

sensor_test = """
; Teste de sensores e operações básicas
INICIAR

; Lê sensores
READSENSOR R1 peso
READSENSOR R2 temperatura

; Processa dados
ADD R1 R2      ; Soma peso e temperatura
SET VELOCIDADE R1

; Controla baseado nos sensores
CMP R1 100
JL normal_mode
JG high_mode

normal_mode:
    SET INCLINACAO 5
    GOTO end

high_mode:
    SET INCLINACAO 15

end:
STATUS
PARAR
HALT
"""

def test_vm():
    """Testa a VM com diferentes programas"""
    vm = EsteiraVM()
    
    print("🧪 Testando fatorial iterativo...")
    vm.load_program(simple_factorial)
    vm.run()
    
    print("\n" + "="*50)
    print("🧪 Testando sensores...")
    vm2 = EsteiraVM()
    vm2.load_program(sensor_test)
    vm2.run()

def load_and_run_asm_file(filename: str, max_steps: int = 1000):
    """Carrega e executa um arquivo assembly"""
    try:
        with open(filename, 'r') as f:
            asm_code = f.read()
        
        print(f"📁 Carregando programa: {filename}")
        print("=" * 50)
        
        vm = EsteiraVM()
        vm.load_program(asm_code)
        
        print("✅ Programa carregado com sucesso!")
        print(f"📊 Número de instruções: {len(vm.program)}")
        print(f"🏷️  Labels encontrados: {list(vm.labels.keys())}")
        print("=" * 50)
        
        vm.run(max_steps)
        
        print("\n🎯 Execução finalizada!")
        vm.print_status()
        
    except FileNotFoundError:
        print(f"❌ Arquivo não encontrado: {filename}")
    except Exception as e:
        print(f"❌ Erro durante execução: {e}")

def main():
    import sys
    
    if len(sys.argv) == 2:
        filename = sys.argv[1]
        if filename.endswith('.asm'):
            load_and_run_asm_file(filename)
        else:
            print("❌ Por favor, forneça um arquivo .asm")
    elif len(sys.argv) == 1:
        print("🧪 Executando testes internos...")
        test_vm()
    else:
        print("Uso: python TreadmillVM.py [arquivo.asm]")
        print("Ex: python TreadmillVM.py programa.asm")
        print("Ex: python TreadmillVM.py (para testes internos)")

if __name__ == "__main__":
    # test_vm()
    main()