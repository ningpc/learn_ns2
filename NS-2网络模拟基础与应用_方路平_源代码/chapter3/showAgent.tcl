proc showAgent {arg} {
	foreach c [$arg info subclass] {
		puts $c
		if {[$c info subclass]!=""}
			{
			showAgent $c
			}
		}
	}
showAgent "Agent"
