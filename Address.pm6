unit class Address;

has IO::Socket::Async $.sock .= udp;
has Str               $.host  = "localhost";
has UInt              $.port  = 9999;

method send($news)    {
    $!sock.print-to: $!host, $!port, $news.Str
}
