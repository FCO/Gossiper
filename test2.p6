use Gossiper;

my Gossiper $g .= new: :host<localhost>, :9998port;
$g.add-node: :host<localhost>, :9999port;
$g.add-news: :noun<node>, :verb<add>, :params{:host<localhost>, :9998port};

await $g.start
