require 'plutolib/logger_utils'

module Plutolib
  module StatelessDelayedJob
    def self.included(base)
      base.class_eval <<-RUBY
        include Plutolib::LoggerUtils
      RUBY
    end

    def error(job, exception)
      log_exception exception
    end

    protected
    
      def log_exception(exc)
        classname = self.class.name.humanize
        backtrace = exc.respond_to?(:backtrace) ? exc.backtrace : []
        error_title = "#{classname} exception: #{exc.class.name}: #{exc.message}"
        log "#{error_title}\n" + backtrace.join("\n")
        if Rails.env.production?
          Airbrake.notify :error_class => classname, :error_message => error_title, :backtrace => backtrace
        end
      end
  end
end