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
has SetHash           $!seed                   .= new;
has Lock              $!node-lock              .= new;

has Supply            $.supply;

sub node-for-params(
    Str  :$id?,
    Str  :$host?,
    Str  :$advertise-host?,
    UInt :$udp-port?,
    UInt :$tcp-port?,
    UInt :$advertise-udp-port?,
    UInt :$advertise-tcp-port?,
) {
    my %params;
    %params<id>                = $_ with $id;
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

multi method add-seed(Str() $host-and-port where /$<host>=[[\w|'.']+] ':' $<port>=[\d+]/) {
    $.add-seed(:host(~$<host>), :port(+$<port>))
}

multi method add-seed(Str() $host, UInt $port) {
    $.add-seed(:$host, :port($port))
}

multi method add-seed(Str() :$host, UInt :$port) {
    $.add-seed(Node.new: :$host, :tcp-port($port), :udp-port($port))
}

multi method add-seed(Node $node) {
    $!seed{ $node } = True
}

multi method add-node(*%params) {
    $.add-node(node-for-params |%params)
}

multi method add-node(Node $node) {
    $!node-lock.lock;
    #note "new node => {$node.perl}";
    $!nodes{ $node } = True;
    $!node-lock.unlock;
}

multi method remove-node(*%params) {
    $.remove-node(node-for-params |%params)
}

multi method remove-node(Node $node) {
    $!node-lock.lock;
    $!nodes{ $node } = False;
    $!node-lock.unlock;
}

method pick-node {
    my Node $node;
    $!node-lock.lock;
    if $!nodes.elems {
        $node = $!nodes.pick;
    }
    $!node-lock.unlock;
    $node
}

multi method add-news(Str :$id, Str :$subject, Str :$action where <create modify delete add remove>.one, :%params) {
    my %pars;
    %pars<id>         = $_ with $id;
    %pars<subject>    = $_ with $subject;
    %pars<action>     = $_ with $action;
    %pars<params>     = %params;
    my $news = News.new: |%pars;
    $.add-news($news)
}

multi method add-news(News $news) {
    $!node-lock.lock;
    $!news{ $news } = $!initial-weight-by-node * ($!nodes.elems + 1);
    $!node-lock.unlock;
    $!old-news{ $news } = True;
}

method stop {
    $!done.keep
}

method start {
    $!done     .= new;
    $.add-news(:action<add>, :subject<node>, :params($!address.Hash));
    note "====> {$!address.perl}";
    my Node $seed = $!seed.pick;
    start {
        use JSON::Pretty;
        #CATCH {
        #    default {
        #        say "Deu ruim! $_";
        #    }
        #}
        react {
            whenever signal(SIGINT) {
                done
            }
            whenever $!done {
                done
            }
            whenever $.listen -> $conn {
                #note "conn: $conn";
                #note $!old-news.keys.Array;
                my $str-old-news = to-json [$!old-news.keys.map: *.Hash];
                #note "str-old-news: $str-old-news";
                $conn.print: $str-old-news ~ "\n";
                $conn.close;
            }
            $!supply = supply {
                if $seed {
                    whenever $seed.connect -> $prom {
                        #note "prom: $prom";
                        whenever $prom.Supply -> $v {
                            #note "tcp: $v";
                            with $v {
                                #note $v;
                                for |.&from-json -> $news {
                                    my News $n .= new: |$news;
                                    #note "news: {$n.perl}";
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
                        note "received: {$n.perl}";
                        $.add-news( $n );
                        emit $n
                    }
                }
            }
            whenever $!supply.grep: { .DEFINITE and .subject ~~ "node" } -> News $news {
                #note "new news!!! {$news.perl}";
                given $news.action {
                    when "add" {
                        note "adding node: {$news.params.perl}";
                        $.add-node(|$news.params)
                    }
                    when "remove" {
                        $!node-lock.lock;
                        note "nodes: {$!nodes.perl}";
                        $!node-lock.unlock;
                        note "remove: {$news.params<id>}";
                        $.remove-node(|$news.params)
                    }
                }
            }
            whenever Supply.interval: $!interval / 1000, :delay(rand * $!interval / 1000) {
                #note "interval";
                with $.pick-node -> $node {
                    #note "chosen node => {$node.perl}";
                    with $!news.pick -> News $news {
                        #note "chosen news => {$news.perl}";
                        #note "Sending: ", $news;
                        $!news{ $news } *= .99999;
                        my Msg $msg .= new: :to($node), :from($!address), :$news;
                        $node.send: $msg.to-json;
                    }
                }
            }
        }
        LEAVE {
            note "quiting";
            $!node-lock.lock;
            for $!nodes.keys -> $node {
                note "sending remove '{$!address.id}' to $node";
                my Msg $msg .= new:
                    :to($node),
                    :from($!address),
                    :news(
                        News.new:
                            :action<remove>,
                            :subject<node>,
                            :params($!address.Hash)
                    )
                ;
                $node.send: $msg.to-json;
            }
            $!node-lock.unlock;
        }
    }
}
