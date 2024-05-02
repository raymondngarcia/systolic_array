### Systolic Array DV Block Level Verification Plan
An ideal verification plan lists **what** needs to be verified at the minimum. How each test item is verified can also be included if schedule and overall DV strategy requires it.

| Test Item Name          | CODE                  | Description  |
| ----------------------- | --------------------- | -------------|
| Matrix Multiplication   | **SA-MM**             | Verify that matrix multiplication is correct |
| Matrix Size N=M         | **SA-SIZE-NEQM**      | Verify that matrix multiplcation is correct for **N=M** |
| Matrix Size N!=M        | **SA-SIZE-NNEQM**     | Verify that matrix multiplcation is correct for **N > M** and **N < M** |
| Initial Output          | **SA-MM-OUT-INIT**    | Verify that DUT output is within allowable time during the very first COUT output |
| Succeeding OUTput       | **SA-MM-OUT-B2B**     | Verify that back-to-back matrix multiplication is output and the gap is exacly M computing delay cycles |
| Reset                   | **SA-RESET**          | Verify that DUT can reset and perform still meet all other test-items after reset |
| Clock                   | **SA-CLK**            | Verify that DUT can support various clock frequency use cases |
| Data Width A and B      | **SA-DW-AB**          | Verify that DUT can support configurable signed data width based on **DIN_WIDTH**  |
| Data Width CIN and COUT | **SA-DW-CIN-COUT**    | Verify that DUT can support configurable signed data width based on **2xDIN_WIDTH** |
| Data IN Valid           | **SA-IN-VALID**       | Verify that DUT can evaluate the data input valid signal correctly and compute based on it |
| Data OUT Valid          | **SA-OUT-VALID**      | Verify that DUT asserts and negates the data output valid signal at the correct timing |
| Data CIN                | **SA-CIN**            | Verify that DUT can support random input values of CIN |

### Systolic Array DV Subsystem Level Verification Plan
| Test Item Name          | CODE                   | Description  |
| ----------------------- | ---------------------- | -------------|
| SA N instances          | **SUBSYS-SA-INST**         | Verify the several instances of SA can be connected to each other and still performs correct matrix multiplication |
| Clock Ratio             | **SUBSYS-SA-CLK-RATIO**    | Verify all required combinations of sys_clk and sr_clk frequencies |
| Data Alignment          | **SUBSYS-SA-DATA-ALIGN**   | Verify that data can be a aligned to the required data alignment using the SA Controller. Verify all types of alignment. |
| System BUS Width        | **SUBSYS-SA-BUS-WIDTH**    | Verify that using bus width of **2xDIN_WIDTHxN** can perform all required matrix multiplication use cases. |
| M Minus One             | **SUBSYS-SA-M-MINUS-1**    | Verify correctness of **SA-MM** among instances of SA based the M_minus_one signal. |
| FIFO Conditions         | **SUBSYS-SA-FIFO**         | Verify all FIFO conditions: FULL, EMPTY, ALMOST FULL |