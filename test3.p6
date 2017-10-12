use Gossiper;

my $host = q:x{ip addr | grep global | perl -nae 'print((split("/", $F[1]))[0])'};
my Gossiper $g .= new: :$host, :port(%*ENV<PORT>.Int);
$g.add-node: :host<center>, :9999port;

react {
	whenever $g.start {
		done
	}
	whenever Supply.interval: 5 {
		say $g.nodes
	}
	whenever Promise.in: 20 + rand * 10 {
		$g.stop
	}
}

note "=====================================>     SAIU!!!!"
