typedef struct packed {
    logic invalid;
    logic [3:0] length;
    logic lock;
    RepPrefix rep;
    SR_t segment;
    logic has_segment_override;
    logic has_modrm;
    logic [1:0][15:0] immediates;
    logic [15:0] displacement;
    logic [7:0] mod_rm;
    logic [7:0] opcode;
} Instruction;