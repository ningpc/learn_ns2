#file:subclass.tcl ;#查询子类的Tcl脚本源码
#Query the subclass for given class ;#查询给定类的子类
if {$argc==1} {
  set motherclass [lindex $argv 0]  ;#查询被查询的类
} else {
  puts "Usage:$argv0 targetclass"
  exit 1
       }
foreach cl [$motherclass info subclass] {
  puts $cl                          ;#输出被查询类的所有子类
}