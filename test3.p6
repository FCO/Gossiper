use Gossiper;
sleep 5;

my $host = %*ENV<HOST> || q:x{ip addr | grep global | perl -nae 'print((split("/", $F[1]))[0])'};
my Gossiper $g .= new: :$host, :8889udp-port, :8888tcp-port;
$g.add-node: :host<center>, :9999udp-port, :9998tcp-port;

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
