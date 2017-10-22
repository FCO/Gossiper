unit role ToHash;
method Hash(--> Hash()) {
	self.^attributes
		.grep(*.has_accessor)
		.map: {
			.name.substr(2) => .get_value: self
		}
}
