module Plutolib
  module GoogleDriveUtils
    MAX_RETRIES=3
    def gd_retries(&block)
      attempts = 0
      while ((attempts += 1) <= MAX_RETRIES)
        begin
          return yield
        rescue Google::Apis::ServerError => exception
          if attempts == MAX_RETRIES
            log_error "Server Error on attempt #{attempts}.  Giving up..."
            raise $!
          else
            log_error "Server Error on attempt #{attempts}.  Retrying..."
            log_error "#{exception.class.name} #{exception.message}" + exception.backtrace.join("\n")
          end
        rescue
          raise $!
        end
      end
    end

    def self.included base
      base.class_eval do
        include Plutolib::LoggerUtils
      end
    end
  end
end