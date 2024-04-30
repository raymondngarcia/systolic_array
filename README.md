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
CVA6V DV Mini-SOC TestBench is originally authored by @raymond.garcia. The whole verification team for CVA6V DV is shown in the table below:

|  Module/Tool       | Description         |
| ------------------ | ------------------- |
| ***Bender***       | Main compilation flow. For more info, refer to [Pulp Bender](https://github.com/pulp-platform/bender) |
| ***VCS***          | Just the preferred compiler/simulator. The makefiles only support VCS compilation and simulation   |
| ***UVM***          | Home directory for UVM version 1.2 and up                                                   |


### Systolic Array Testbench Diagram

![*Example*](img/sa_tb.png)

#### Overview - module level
HDL Top instantiates *sa* which is the Systolic Array Design Under Test (DUT). The UVM Verification Testbench components are listed in the following table.

| Components              | Description |
| ----------------------- | ----------- |
| test                    | Under $REPO_ROOT/uvm/tests.  |
| sequences               | Under $REPO_ROOT/uvm/sequences. |
| env                     | Under $REPO_ROOT/uvm/env. |
| agents/sa_agent         | Under $REPO_ROOT/uvm/agents/sa_agent |
| scoreboards/sa_sb       | Under $REPO_ROOT/uvm/scoreboards/sa_sb |
| refmodels/sa_refmodel   | Under $REPO_ROOT/uvm/refmodels/sa_refmodel|
| rtl                     | Under $REPO_ROOT/rtl |
| uvm_pkg                 | Under $REPO_ROOT/uvm_pkg |
| sim                     | Under $REPO_ROOT/sim |

### Overview - subsytem level
![*Example*](img/subsys.png)

#### Overview
TODO

| Components              | Description |
| ----------------------- | ----------- |
| TODO                    | TODO        |
| TODO                    | TODO        |
| TODO                    | TODO        |
| TODO                    | TODO        |


#### Setting the CVA6V Mini-Soc Environment
Follow these steps to setup the Mini-SoC TestBench:

```bash
git clone https://github.com/raymondngarcia/systolic_array.git
cd <repo-dir>
source .env-default-modules
cd sim
```

#### Single simulation example command
```bash
make run_vcs TESTNAME=sa_sanity_test
```

#### Metrics / Coverage Plan
VPlan / Verification IQ excel / csv file

- [Vplan]()
