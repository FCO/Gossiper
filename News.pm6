use JSON::Class;
class News does JSON::Class {
    use UUID;
    has Str $.id = ~UUID.new: :4version;
    has Str $.noun;
    has Str $.verb where <create modify delete add remove>.one;
    has     %.params;

    multi method WHICH(::?CLASS:D:) {"News|" ~ $!id}
    multi method WHICH(::?CLASS:U:) {"News|[[UNDEFINED]]"}
}
