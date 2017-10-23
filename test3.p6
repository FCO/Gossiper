use Gossiper;

subset PortNumber of Int where 0 < * < 65535;

my $lhost = %*ENV<HOST> || q:x{ip addr | grep global | perl -nae 'print((split("/", $F[1]))[0])'};
sub MAIN(
	*@seed,
	:$host = $lhost,
	PortNumber() :$udp-port = 8889,
	PortNumber() :$tcp-port = 8888,
	UInt() :$delay = 0,
	UInt() :$ttl = 50
) {
	my Gossiper $g .= new: :$host, :udp-port($udp-port.Int), :tcp-port($tcp-port.Int);
	sleep $delay;
	$g.add-seed: $_ for @seed;

	react {
		whenever $g.start {
			done
		}
		whenever Supply.interval: 5 {
			say $g.nodes.keys>>.host.sort
		}
		whenever Promise.in: $ttl + rand * $ttl {
			$g.stop
		}
	}

	note "=====================================>     SAIU!!!!";
}
