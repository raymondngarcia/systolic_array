`ifndef __SA_IF_SV__
`define __SA_IF_SV__


interface sa_if # (
  parameter int unsigned DIN_WIDTH = 'd8,
  parameter int unsigned N = 'd4
);

  logic rst_n;
  logic clk;
  logic [N-1:0][2*DIN_WIDTH-1:0]  c_din;
  logic [N-1:0][DIN_WIDTH-1:0]    a_din;
  logic [N-1:0][DIN_WIDTH-1:0]    b_din;
  logic in_valid;                            // A and B matrix last element ready

  logic [N-1:0][2*DIN_WIDTH-1:0]  c_dout;
  logic out_valid;                           // C matrix last element ready

  clocking mon @(posedge clk);
    input rst_n;
    input c_din;
    input a_din;
    input b_din;
    input in_valid;
    input c_dout;
    input out_valid;
  endclocking

  clocking drv @(posedge clk);
    output c_din;
    output a_din;
    output b_din;
    output in_valid;
    output c_dout;    // should be input but we have no DUT so this will do
    output out_valid; // should be input but we have no DUT so this will do
  endclocking


endinterface
`endif // __SA_IF_SV__
