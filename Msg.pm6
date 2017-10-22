use UseIdToWhich;
use JSON::Class;
use ToHash;
unit class Msg does JSON::Class does ToHash does UseIdToWhich;
use Node;
use News;
use UUID;

has Node $.from  is json-skip-null;
has Node $.to    is json-skip-null;
has News $.news  is json-skip-null;
