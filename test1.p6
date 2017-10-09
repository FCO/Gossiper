use Gossiper;
say "starting...";

my Gossiper $g .= new: :host<test1>, :9999port;

await $g.start
