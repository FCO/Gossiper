use Gossiper;

my $host = q:x{ip addr | grep global | perl -nae 'print((split("/", $F[1]))[0])'};
my Gossiper $g .= new: :$host, :port(%*ENV<PORT>.Int);
$g.add-node: :host<center>, :9999port;

start react whenever Supply.interval: 5 {
	say $g.nodes
}

await $g.start
