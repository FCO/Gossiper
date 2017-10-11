use Gossiper;

my Gossiper $g .= new: :host(%*ENV<HOST>), :port(%*ENV<PORT>.Int);
$g.add-node: :host<center>, :9999port;

start react whenever Supply.interval: 5 {
	say $g.nodes
}

await $g.start
