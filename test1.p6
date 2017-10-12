use v6.d.PREVIEW;
use Gossiper;

my Gossiper $g .= new: :host<center>, :9999port;

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
