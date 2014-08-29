module Plutolib
	class RegexUtils
		def self.extract_email(text)
			if text =~ /(\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b)/i
				$1
			else
				nil
			end
		end
		##
		# Returns [name, email]
		def self.extract_email_parts(text)
			if text =~ /([^<]+) <([^>]+)>/i
				[$1.strip, $2.strip]
			elsif email = self.extract_email(text)
				[nil, email]
			else
				nil
			end
		end	
	end
end