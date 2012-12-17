module Plutolib::WithRetries  
  def with_retries(&block)
    self.class.with_retries(&block)
  end
  
  MAX_RETRIES=3
  def self.with_retries(&block)
    attempts = 0
    while ((attempts += 1) <= MAX_RETRIES)
      begin
        return yield
      rescue ActiveResource::ServerError => exception
        if attempts == MAX_RETRIES
          log_error "Server Error on attempt #{attempts}.  Giving up..."
          raise $!
        else
          log_error "Server Error on attempt #{attempts}.  Retrying..."
          log_error "#{exception.class.name} #{exception.message}" + exception.backtrace.join("\n")
        end
      rescue ActiveResource::TimeoutError
        if attempts == MAX_RETRIES
          log_error "Timeout on attempt #{attempts}.  Giving up..."
          raise $!
        else
          log_error "Timeout on attempt #{attempts}.  Retrying..."
        end
      rescue EOFError
        if attempts == MAX_RETRIES
          log_error "EOFError on attempt #{attempts}.  Giving up..."
          raise $!
        else
          log_error "EOFError on attempt #{attempts}.  Retrying..."
        end
      rescue
        raise $!
      end
    end
  end
end