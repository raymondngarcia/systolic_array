`ifndef GUARD_SA_PKG_SV
`define GUARD_SA_PKG_SV

package sa_pkg;

  parameter int unsigned N = 2;
  parameter int unsigned M = 2;
  parameter int unsigned DIN_WIDTH = 8;
  parameter int unsigned BUS_WIDTH = 2*DIN_WIDTH*N;

endpackage : sa_pkg
`endif
