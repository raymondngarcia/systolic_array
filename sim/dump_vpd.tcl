# TCL file invoked from VCS's simv at run-time using this: -ucli -do <this file>

if {[info exists ::env(TESTNAME)]} {
  set dumpname $::env(TESTNAME)
} else {
  set dumpname "test"
}
append dumpname "_seed_"
if {[info exists ::env(SEED)]} {
  append dumpname $::env(SEED)
  append dumpname "."
} else {
  append dumpname "1."
}
if {[info exists ::env(VCS_DUMP_TYPE)]} {
  append dumpname $::env(VCS_DUMP_TYPE)
}

dump -file $dumpname -type VPD
call {$vcdpluson(0, hdl_top)}

run
quit
