`ifndef __SA_SV__
`define __SA_SV__


module sa # (
  parameter int unsigned DIN_WIDTH = 'd8,
  parameter int unsigned N = 'd4
)(
  input logic rst_n,
  input logic clk,
  input logic [2*DIN_WIDTH-1:0]  c_din[0:N-1],
  input logic [DIN_WIDTH-1:0]  a_din[0:N-1],       // N elements of A matrix (column)
  input logic [DIN_WIDTH-1:0]  b_din[0:N-1],       // N elements of B matrix (row)
  input logic in_valid,                            // A and B matrix last element ready

  output logic [2*DIN_WIDTH-1:0]  c_dout[N-1:0],
  output logic out_valid                           // C matrix last element ready
);
endmodule
`endif // __SA_SV__