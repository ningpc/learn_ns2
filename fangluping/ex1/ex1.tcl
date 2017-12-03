# The preamble
set ns [new Simulator]

$ns color 0 blue
$ns color 1 red
$ns color 2 white

# Predefine tracing
set f [open out.tr w]
$ns trace-all $f
set nf [open out.nam w]
$ns namtrace-all $nf

set n0 [$ns node]
set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]

$ns duplex-link $n0 $n2 2Mb 10ms DropTail
$ns duplex-link $n1 $n2 2Mb 10ms DropTail
$ns duplex-link $n2 $n3 1.7Mb 20ms DropTail
$ns queue-limit $n2 $n3 10

$ns duplex-link-op $n0 $n2 orient right-up
$ns duplex-link-op $n1 $n2 orient right-down
$ns duplex-link-op $n2 $n3 orient right
$ns duplex-link-op $n2 $n3 queuePos 0.5

set tcp [new Agent/TCP]
#$tcp set class_ 2
$ns attach-agent $n0 $tcp

set sink [new Agent/TCPSink]
$ns attach-agent $n3 $sink
$ns connect $tcp $sink
$tcp set fid_ 1

set ftp [new Application/FTP]	;# TCP does not generate its own traffic;
$ftp attach-agent $tcp

set udp [new Agent/UDP]		;# A UDP agent;
$ns attach-agent $n1 $udp		;# on node $n0;
set null [new Agent/Null]		;# Its sink;
$ns attach-agent $n3 $null		;# on node $n3;
$ns connect $udp $null
$udp set fid_ 2

set cbr [new Application/Traffic/CBR]		;# A CBR traffic generator agent;
$cbr attach-agent $udp		;# attached to the UDP agent;
$cbr set type_ CBR
$cbr set packet_size_ 1000
$cbr set rate_ 1mb
$cbr set random_ false

$ns at 0.1 "$cbr start"
$ns at 1.0 "$ftp start"
$ns at 4.0 "$ftp stop"
$ns at 4.5 "$cbr stop"

$ns at 5 "finish"
proc finish {} {
        global ns f nf
        $ns flush-trace
        close $f
        close $nf

        puts "running nam..."
        exec nam out.nam &
        exit 0
}

# Finally, start the simulation.
$ns run
