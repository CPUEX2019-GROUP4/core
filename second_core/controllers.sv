`default_nettype none
`include "common_params.h"


module stall_instructor (
  input wire [`OPCODE_W  -1:0] dec_opcode,
  input wire [`FUNCT_W   -1:0] dec_funct,
  input wire [`OPCODE_W  -1:0] exec_opcode,
  input wire [`FUNCT_W   -1:0] exec_funct,
  input wire                   exec_be,
  input wire [`OPCODE_W  -1:0] ma_opcode,
  input wire [`FUNCT_W   -1:0] ma_funct,
  input wire                   ma_be,
  input wire [`OPCODE_W  -1:0] wb_opcode,
  input wire [`FUNCT_W   -1:0] wb_funct,
  input wire                   wb_be,

  input wire                   forward_from_exec,
  input wire                   forward_from_ma,
  input wire                   forward_from_wb,
  
  input wire                   in_busy,
  input wire                   out_busy,

  output reg                   flush,
  output reg                   stall_phases,
  output reg                   stall_pc,

  input wire                   clk,
  input wire                   rstn
);

  wire load_inst_in_dec_phase;
  wire load_inst_in_exec_phase;
  wire load_inst_in_ma_phase;
  wire load_inst_in_wb_phase;

  load_inst_detector li1(exec_opcode, load_inst_in_exec_phase);
  load_inst_detector li2(  ma_opcode, load_inst_in_ma_phase);
  load_inst_detector li3(  wb_opcode, load_inst_in_wb_phase);

  wire stall_pc_due_to_io =
    (dec_opcode==`OPCODE_ININT&&(in_busy)) ? 1 :
    (dec_opcode==`OPCODE_INFLT&&(in_busy)) ? 1 :
    (dec_opcode==`OPCODE_OUT &&(out_busy)) ? 1 : 0;

  wire stall_pc_due_to_load =
    (load_inst_in_exec_phase&& forward_from_exec) ? 1 :
    (load_inst_in_ma_phase  && forward_from_ma  ) ? 1 :
    (load_inst_in_wb_phase  && forward_from_wb  ) ? 1 : 0;

  assign stall_pc     = stall_pc_due_to_io | stall_pc_due_to_load;
  assign stall_phases = stall_pc_due_to_io | stall_pc_due_to_load | (|stall_delay);
  assign flush        = exec_be | (|flush_delay);

  reg [2:0] flush_delay;
  reg [2:0] stall_delay;
  
  always @(posedge clk) begin
    flush_delay <=(~rstn)          ? 0 :
                  (exec_be)        ? 3 :
                  (flush_delay==0) ? 0 : flush_delay-1;
    stall_delay <=(~rstn)          ? 0 :
                  (stall_pc)       ? 2 :
                  (stall_delay==0) ? 0 : stall_delay-1;
  end
endmodule

  
module forwarding_instructor (
  input  wire [`OPCODE_W  -1:0] dec_opcode,
  input  wire [`FUNCT_W   -1:0] dec_funct,
  input  wire [`REG_ADDR_W-1:0] dec_rd_addr,
  input  wire [`REG_ADDR_W-1:0] dec_rs_addr,
  input  wire [`REG_ADDR_W-1:0] dec_rt_addr,
  input  wire [`OPCODE_W  -1:0] exec_opcode,
  input  wire [`FUNCT_W   -1:0] exec_funct,
  input  wire [`REG_ADDR_W-1:0] exec_rd_addr,
  input  wire [`OPCODE_W  -1:0] ma_opcode,
  input  wire [`FUNCT_W   -1:0] ma_funct,
  input  wire [`REG_ADDR_W-1:0] ma_rd_addr,
  input  wire [`OPCODE_W  -1:0] wb_opcode,
  input  wire [`FUNCT_W   -1:0] wb_funct,
  input  wire [`REG_ADDR_W-1:0] wb_rd_addr,
  
  output wire                   forward_to_d_from_exec,
  output wire                   forward_to_s_from_exec,
  output wire                   forward_to_t_from_exec,
  output wire                   forward_to_d_from_ma,
  output wire                   forward_to_s_from_ma,
  output wire                   forward_to_t_from_ma,
  output wire                   forward_to_d_from_wb,
  output wire                   forward_to_s_from_wb,
  output wire                   forward_to_t_from_wb,

  input  wire                   clk,
  input  wire                   rstn
);
  wire dec_from_gd, dec_from_fd;
  wire dec_from_gs, dec_from_fs;
  wire dec_from_gt, dec_from_ft;
  wire  exec_to_gd,  exec_to_fd;
  wire   dec_to_gd,   dec_to_fd;
  wire    ma_to_gd,    ma_to_fd;
  wire    wb_to_gd,    wb_to_fd;

  register_usage_table table1 (
    .opcode     (dec_opcode),
    .funct      (dec_funct),
    .d_from_gpr (dec_from_gd),
    .d_from_fpr (dec_from_fd),
    .s_from_gpr (dec_from_gs),
    .s_from_fpr (dec_from_fs),
    .t_from_gpr (dec_from_gt),
    .t_from_fpr (dec_from_ft)
  );
  register_usage_table table2 (
    .opcode   (exec_opcode),
    .funct    (exec_funct),
    .d_to_gpr (exec_to_gd),
    .d_to_fpr (exec_to_fd)
  );
  register_usage_table table3 (
    .opcode   (ma_opcode),
    .funct    (ma_funct),
    .d_to_gpr (ma_to_gd),
    .d_to_fpr (ma_to_fd)
  );
  register_usage_table table4 (
    .opcode   (wb_opcode),
    .funct    (wb_funct),
    .d_to_gpr (wb_to_gd),
    .d_to_fpr (wb_to_fd)
  );

  assign forward_to_d_from_exec =
    (dec_rd_addr==exec_rd_addr) &
    ((dec_from_gd&exec_to_gd)|(dec_from_fd&exec_to_fd));
  
  assign forward_to_s_from_exec =
    (dec_rs_addr==exec_rd_addr) &
    ((dec_from_gs&exec_to_gd)|(dec_from_fs&exec_to_fd));
  
  assign forward_to_t_from_exec =
    (dec_rt_addr==exec_rd_addr) &
    ((dec_from_gt&exec_to_gd)|(dec_from_ft&exec_to_fd));
  
  assign forward_to_d_from_ma =
    (dec_rd_addr==ma_rd_addr) &
    ((dec_from_gd&ma_to_gd)|(dec_from_fd&ma_to_fd));
  
  assign forward_to_s_from_ma =
    (dec_rs_addr==ma_rd_addr) &
    ((dec_from_gs&ma_to_gd)|(dec_from_fs&ma_to_fd));
  
  assign forward_to_t_from_ma =
    (dec_rt_addr==ma_rd_addr) &
    ((dec_from_gt&ma_to_gd)|(dec_from_ft&ma_to_fd));

  assign forward_to_d_from_wb =
    (dec_rd_addr==wb_rd_addr) &
    ((dec_from_gd&wb_to_gd)|(dec_from_fd&wb_to_fd));
  
  assign forward_to_s_from_wb =
    (dec_rs_addr==wb_rd_addr) &
    ((dec_from_gs&wb_to_gd)|(dec_from_fs&wb_to_fd));
  
  assign forward_to_t_from_wb =
    (dec_rt_addr==wb_rd_addr) &
    ((dec_from_gt&wb_to_gd)|(dec_from_ft&wb_to_fd));

endmodule


module branch_inst_detector (
  input wire [`OPCODE_W-1:0] opcode,
  input wire [`FUNCT_W -1:0] funct,
  output reg                 is_branch_inst
);
  function f (
    input [`OPCODE_W-1:0] opcode,
    input [`FUNCT_W -1:0] funct
  );
  begin
    case (opcode)
      `OPCODE_R: begin
        case (funct)
          `FUNCT_JR  : f = 1;
          `FUNCT_JALR: f = 1;
          default    : f = 0;
        endcase
      end
      `OPCODE_BEQ : f = 1;
      `OPCODE_BNE : f = 1;
      `OPCODE_J   : f = 1;
      `OPCODE_JAL : f = 1;
      `OPCODE_BC1T: f = 1;
      `OPCODE_BC1F: f = 1;
      default     : f = 0;
    endcase
  end
  endfunction

  assign is_branch_inst = f (opcode,funct);
  
endmodule

module load_inst_detector (
  input wire [`OPCODE_W-1:0] opcode,
  output reg                 is_load_inst
);
  assign is_load_inst =
    (opcode==`OPCODE_LW   ) ? 1 :
    (opcode==`OPCODE_LWCZ ) ? 1 :
    (opcode==`OPCODE_ININT) ? 1 :
    (opcode==`OPCODE_INFLT) ? 1 : 0;
endmodule

`default_nettype wire
