use UseIdToWhich;
use JSON::Class;
use ToHash;
unit class News does JSON::Class does ToHash does UseIdToWhich;
has Str $.noun;
has Str $.verb where <create modify delete add remove>.one;
has     %.params;

