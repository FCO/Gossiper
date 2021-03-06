# vim: noai:ts=4:sw=4:expandtab
use UseIdToWhich;
use JSON::Class;
use ToHash;
unit class Node does JSON::Class does ToHash does UseIdToWhich;

has Str               $.host                = "0.0.0.0";
has Str               $.advertise-host      = $!host;
has UInt              $.udp-port            is required = 9999;
has UInt              $.tcp-port            is required = 9998;
has UInt              $.advertise-udp-port  = $!udp-port;
has UInt              $.advertise-tcp-port  = $!tcp-port;
has IO::Socket::Async $!sock               .= udp;

method send($news)    {
    $!sock.print-to: $!advertise-host, $!advertise-udp-port, $news.Str
}

method udp-supply {
    my $socket //= IO::Socket::Async.bind-udp: $.host, $.udp-port;
	$socket.Supply.grep: *.chars > 0
}

method connect {
	IO::Socket::Async.connect($!advertise-host, $!advertise-tcp-port)
}

method listen {
	IO::Socket::Async.listen($!host, $!tcp-port)
}
