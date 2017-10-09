use Gossiper;

my Gossiper $g .= new: :host<localhost>, :9999port;

await $g.start
