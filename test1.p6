use Gossiper;

my Gossiper $g .= new: :host<center>, :9999port;

start react whenever Supply.interval: 5 {
	say $g.nodes
}

await $g.start
