# vim: noai:ts=4:sw=4:expandtab
unit class Gossiper;
use JSON::Class;
use Node;
use News;
use Msg;

multi to-json(JSON::Class:D $obj, |) {$obj.to-json}
multi to-json(JSON::Class:U $obj, |) {""}

has Node              $.address   handles <host advertise-host udp-port tcp-port udp-supply listen>;
has SetHash           $.nodes;
has UInt              $.interval                = 50;
has UInt              $.initial-weight-by-node  = 5;
has Promise           $!done;
has BagHash           $!news                   .= new;
has SetHash           $!old-news               .= new;

has Supply            $.supply;

sub node-for-params(
    Str  :$host?,
    Str  :$advertise-host?,
    UInt :$udp-port?,
    UInt :$tcp-port?,
    UInt :$advertise-udp-port?,
    UInt :$advertise-tcp-port?,
) {
    my %params;
    %params<host>              = $_ with $host;
    %params<advertise-host>    = $_ with $host;
    %params<udp-port>          = $_ with $udp-port;
    %params<tcp-port>          = $_ with $tcp-port;
    %params<adverize-udp-port> = $_ with $advertise-udp-port;
    %params<adverize-tcp-port> = $_ with $advertise-tcp-port;

    Node.new: |%params
}

method new(*@nodes, *%params) {
    ::?CLASS.bless:
        :address(node-for-params |%params),
        :nodes(@nodes.SetHash)
}

multi method add-node(*%params) {
    $.add-node(node-for-params |%params)
}

multi method add-node(Node $node) {
    $!nodes{ $node } = True
}

multi method remove-node(*%params) {
    $.remove-node(node-for-params |%params)
}

multi method remove-node(Node $node) {
    $!nodes{ $node } = False
}

multi method add-news(Str :$noun, Str :$verb where <create modify delete add remove>.one, :%params) {
    $.add-news(News.new: :$noun, :$verb, :%params)
}

multi method add-news(News $news) {
    $!news{ $news } = $!initial-weight-by-node * $!nodes.elems;
    $!old-news{ $news } = True;
}

method stop {
    $!done.keep
}

method start {
    $!done     .= new;
    $.add-news(:verb<add>, :noun<node>, :params($!address.Hash));
    my Node $first-node = $!nodes.pick;
    start {
        use JSON::Pretty;
        #CATCH {
        #    default {
        #        say "Deu ruim! $_";
        #    }
        #}
        react {
            whenever $!done {
                done
            }
            whenever $.listen -> $conn {
                #note "conn: $conn";
                #note $!old-news.keys.Array;
                my $str-old-news = "[ {$!old-news.keys>>.to-json.join(", ")} ]\n";
                note "str-old-news: $str-old-news";
                $conn.print: $str-old-news;
                $conn.close;
            }
            $!supply = supply {
                if $first-node {
                    whenever $first-node.connect -> $prom {
                        note "prom: $prom";
                        whenever $prom.Supply -> $v {
                            note "tcp: $v";
                            with $v {
                                for |.&from-json -> $news {
                                    my News $n .= new: |$news;
                                    note "news: {$n}";
                                    $.add-news($n);
                                    emit $n
                                }
                            }
                        }
                    }
                }
                whenever $.udp-supply -> $news {
                    my Msg  $m .= from-json: $news;
                    my News $n  = $m.news;
                    if not $!news{ $n }:exists and not $!old-news{ $n } {
                        note "received: ", $n.WHICH;
                        $.add-news( $n );
                        emit $n
                    }
                }
            }
            whenever $!supply.grep: { .noun ~~ "node" } -> News $news {
                given $news.verb {
                    when "add" {
                        $.add-node(|$news.params)
                    }
                    when "remove" {
                        $.remove-node(|$news.params)
                    }
                }
            }
            whenever Supply.interval: $!interval / 1000, :delay(rand * $!interval / 1000) {
                with $!nodes.pick -> $node {
                    with $!news.pick -> News $news {
                        note "Sending: ", $news;
                        $!news{ $news } *= .99999;
                        my Msg $msg .= new: :to($node), :from($!address), :$news;
                        $node.send: $msg.to-json;
                    }
                }
            }
        }
        LEAVE {
            note "quiting";
            for $!nodes.keys -> $node {
                my Msg $msg .= new:
                    :to($node),
                    :from($!address),
                    :news(
                        News.new:
                            :verb<remove>,
                            :noun<node>,
                            :params($!address.Hash)
                    )
                ;
                $node.send: $msg.to-json;
            }
        }
    }
}
