use JSON::Class;
unit class Msg does JSON::Class;
use Node;
use News;
use UUID;

has Str  $.id = ~UUID.new: :4version;
has Node $.from  is json-skip-null;
has Node $.to    is json-skip-null;
has News $.news  is json-skip-null;

multi method WHICH(::?CLASS:D:) {"Msg|$!id"}
multi method WHICH(::?CLASS:U:) {"Msg|[[UNDEFINED]]"}
