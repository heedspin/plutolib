class Plutobug
	class << self
		def breakpoints
			@breakpoints ||= Hash.new(false)
		end
		def set?(key)
			breakpoints[key]
		end
		def set(key)
			breakpoints[key] = true
		end
		def unset(key)
			breakpoints[key] = false
		end
	end
end