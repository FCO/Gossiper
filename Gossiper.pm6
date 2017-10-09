# vim: noai:ts=4:sw=4:expandtab
unit class Gossiper;
use Address;
use News;

has Address           $.advertise handles (:advertise-host<host>, :advertise-port<port>);
has Address           $.address   handles <host port>;
has IO::Socket::Async $.socket;
has SetHash           $.nodes;
has UInt              $.interval        = 50;
has UInt              $.initial-weight  = 50;
has Promise           $!running;
has BagHash           $!news           .= new;
has SetHash           $!old-news       .= new;

has Supply            $.supply;

method new(*@nodes, :$host = "localhost", :$port = 9999, :$advertise-host = $host, :$advertise-port = $port) {
    ::?CLASS.bless: :address(Address.new: :$host, :$port), :$advertise-host, :$advertise-port, :nodes(@nodes.SetHash)
}

multi method add-node(Str() :$host, UInt() :$port) {
    $.add-node(Address.new: :$host, :$port)
}

multi method add-node(Address $node) {
    $!nodes{ $node } = True
}

multi method add-news(Str :$noun, Str :$verb where <create modify delete add remove>.one, :%params) {
    $.add-news(News.new: :$noun, :$verb, :%params)
}

multi method add-news(News $news) {
    $!news{ $news } = $!initial-weight;
    $!old-news{ $news } = True;
}

method start {
    $!running = start {
        $!socket .= bind-udp: $.host, $.port;
        react {
            $!supply = supply {
                whenever $!socket.Supply.grep: *.chars > 0 -> $news {
                    my News $n .= from-json: $news;
                    if not $!news{ $n }:exists and not $!old-news{ $n } {
                        note "received: ", $n.WHICH;
                        $.add-news( $n );
                        emit $n
                    }
                }
            }
            whenever $!supply.grep: { .noun ~~ "node" } -> News:D $news {
                given $news.verb {
                    when "add" {
                        $.add-node(|$news.params)
                    }
                }
            }
            whenever Supply.interval: $!interval / 1000, :delay(rand * $!interval / 1000) {
                if $!nodes.elems {
                    with $!news.pick -> News:D $news {
                        note "Sending: ", $news;
                        $!news{ $news } *= .999;
                        $!nodes.pick.send: $news.to-json: :skip-null;
                    }
                }
            }
        }
    }
}
