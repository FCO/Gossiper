use Gossiper;

my Gossiper $g .= new: :host<localhost>, :9998port;
$g.add-node: :host<localhost>, :9999port;

await $g.start
