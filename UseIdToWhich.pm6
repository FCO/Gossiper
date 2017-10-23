unit role UseIdToWhich;
use UUID;
has Str:D $.id = ~UUID.new: :4version;

multi method WHICH(UseIdToWhich:D:) {"{self.^name}|{self.id}"}
multi method WHICH(UseIdToWhich:U:) {"{self.^name}|[[UNDEFINED]]"}
