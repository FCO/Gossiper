use Gossiper;

my Gossiper $g .= new: :host<test>, :9999port;
$g.add-node: :host<test>, :9999port;

await $g.start
