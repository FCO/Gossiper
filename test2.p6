use Gossiper;
sleep 10;
say "starting...";

my Gossiper $g .= new: :host<test2>, :9999port;
$g.add-node: :host<test1>, :9999port;
$g.add-news: :noun<node>, :verb<add>, :params{:host<test2>, :9999port};

await $g.start
