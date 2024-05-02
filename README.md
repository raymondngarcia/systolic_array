# Systolic Array DV TestBench

## Introduction
The concept of Systolic Array is based on [Wikipedia](https://en.wikipedia.org/wiki/Systolic_array)

### Overview
This is a small testbench project for **Systolic Array**.
This testbench does/is":

 - purely Design Verification code at the moment
 - not have any rtl implementation
 - contains standard UVM components such agent, reference model, scoreboard, env, sequence and test
 - cover very basic matrix muliplication as part of Systolic Array output
 - meant for purely educational and demonstration purpose only


### Prerequisites
Systolic Array is originally authored by @raymond.garcia. The prerequisites to run and compile the testbench are provided below. Also, a compile.sh script which is automatically generated by bender is available under sim directory.

|  Module/Tool       | Description         |
| ------------------ | ------------------- |
| ***Bender***       | Main compilation flow. For more info, refer to [Pulp Bender](https://github.com/pulp-platform/bender) |
| ***VCS***          | Just the preferred compiler/simulator. The makefiles only support VCS compilation and simulation   |
| ***UVM***          | Home directory for UVM version 1.2 and up                                                   |


### Systolic Array Testbench Diagram

![*Example*](img/sa_tb.png) TODO

#### Overview - module level
HDL Top instantiates *sa* which is the Systolic Array Design Under Test (DUT). The directory description is  listed in the following table.

| Directory               | Description |
| ----------------------- | ----------- |
| tests                   | Under $REPO_ROOT/uvm/tests. Contains the base test and a sanity test to run basic simulation |
| sequences               | Under $REPO_ROOT/uvm/sequences. Contains the sequence that initiate the transaction for the Systolica Arra agent|
| env                     | Under $REPO_ROOT/uvm/env. The UVM environment. |
| agents/sa_agent         | Under $REPO_ROOT/uvm/agents/sa_agent. Contains the Systolic Array Agent. |
| scoreboards/sa_sb       | Under $REPO_ROOT/uvm/scoreboards/sa_sb. Contains the Systolic Array Scoreboard |
| refmodels/sa_refmodel   | Under $REPO_ROOT/uvm/refmodels/sa_refmodel. Contains the Systolic Array Reference Model. |
| rtl                     | Under $REPO_ROOT/rtl. Contains the dummy RTL for module and subsystem, interface and parameter packages |
| uvm_pkg                 | Under $REPO_ROOT/uvm_pkg. Contains the bender manifest for UVM |
| sim                     | Under $REPO_ROOT/sim. Simulation directory for module level. |
| sim-subsys              | Under $REPO_ROOT/sim-subsys. Simulation directory for subsystem level. |
| subsys                  | Under $REPO_ROOT/sim-subsys. Contains base test and sanity test for subsystem level. |
| docs                    | Under $REPO_ROOT/docs. Contains the Verification plan |

### Overview - subsytem level
![*Example*](img/subsys.png)

#### Overview
Subsystem Level is instantiating a dummy module **subsys** and two **sa_if** interface. We second interface instance of **sa_if** is just for demonstrating that the test could fail and that the DV environment really does something. There is a driver bug which I intentionally did not fix when **N** is not equal to 2. 



#### Setting the Systolic Array Environment
Follow these steps to setup the Systolic Array TestBench:

```bash
git clone https://github.com/raymondngarcia/systolic_array.git
cd <repo-dir>
source .env-default-modules # note you can use export instead to define VCS_HOME and other licenses
cd sim # for module level, for subssystem level, go to sim-subsys
```

#### Single simulation example command
```bash
make run_vcs TESTNAME=sa_sanity_test  # this is for module level
make run_vcs TESTNAME=sa_subsys_sanity_test  # this is for module level
```
