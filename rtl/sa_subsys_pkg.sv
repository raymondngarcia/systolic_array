`ifndef __SA_SUBSYS_PKG_SV__
`define __SA_SUBSYS_PKG_SV__

package sa_subsys_pkg;

  // First SA instance
  parameter int unsigned N_0 = 2;
  parameter int unsigned M_0 = 2;
  parameter int unsigned DIN_WIDTH_0 = 8;
  parameter int unsigned BUS_WIDTH_0 = 2*DIN_WIDTH_0*N_0;

  // Second SA instance
  parameter int unsigned N_1 = 3;
  parameter int unsigned M_1 = 3;
  parameter int unsigned DIN_WIDTH_1 = 8;
  parameter int unsigned BUS_WIDTH_1 = 2*DIN_WIDTH_1*N_1;

  parameter int unsigned NUM_SA = 2;

endpackage
`endif
