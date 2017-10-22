use Gossiper;

my $lhost = %*ENV<HOST> || q:x{ip addr | grep global | perl -nae 'print((split("/", $F[1]))[0])'};
sub MAIN(*@seed, :$host is copy = $lhost, UInt :$udp-port = 8889, UInt :$tcp-port = 8888, UInt :$delay = 0) {
	my Gossiper $g .= new: :$host, :$udp-port, :$tcp-port;
	sleep $delay;
	$g.add-seed: $_ for @seed;

	react {
		whenever $g.start {
			done
		}
		whenever Supply.interval: 5 {
			say $g.nodes
		}
		#whenever Promise.in: 20 + rand * 10 {
		#	$g.stop
		#}
	}

	note "=====================================>     SAIU!!!!";
}
