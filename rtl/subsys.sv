
`ifndef __SUBSYS_SV__
`define __SUBSYS_SV__


module subsys #(
  parameter int unsigned DIN_WIDTH = 'd8,
  parameter int unsigned N = 'd4,
  parameter int unsigned BUS_WIDTH = 2*DIN_WIDTH*N
) (
  input  logic                rst_n,
  input  logic                sys_clk,
  input  logic                sr_clk,
  input  logic[7:0]           M_minus_one,
  input  logic[BUS_WIDTH-1:0] din,
  input  logic                wr_fifo,
  input  logic                rd_fifo,
  output logic                in_fifo_full,
  output logic[BUS_WIDTH-1:0] dout,
  output logic                out_fifo_empty
);

endmodule


`endif // __SUBSYS_SV__