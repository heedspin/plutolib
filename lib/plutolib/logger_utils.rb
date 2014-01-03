module Plutolib
  module LoggerUtils
    module Methods
      def loggers=(*args)
        @loggers = args.flatten
      end
      def loggers
        @loggers ||= self.class.loggers.clone
      end
      def log_to_stdout
        @logging_to_stdout = true
        self.loggers.push Logger.new(STDOUT)
      end
      def logging_to_stdout?
        @logging_to_stdout
      end
      def log(msg)
        self.loggers.each do |logger|
          logger.info "#{self.class.name.demodulize}: #{msg}"
        end
        msg
      end
      def log_error(msg, exception=nil)
        exception_msg = if exception
          "\n#{exception.class.name} #{exception.message}\n" + exception.backtrace.join("\n")
        end
        self.loggers.each do |logger|
          logger.error "#{self.class.name.demodulize}: #{msg}#{exception_msg}"
        end
        msg
      end
    end
    def self.included(base)
      base.send(:include, Methods)
      base.class_eval <<-RUBY
      @@loggers = nil
      def self.loggers
        @@loggers ||= [AppConfig.delayed_job ? Delayed::Worker.logger : (ActiveRecord::Base.logger || Rails.logger)]
      end
      @@logging_to_stdout = false
      def self.log_to_stdout
        @@logging_to_stdout = true
        self.loggers.push Logger.new(STDOUT)
      end
      def self.logging_to_stdout?
        @@logging_to_stdout
      end
      def self.log(msg)
        self.loggers.each do |logger|
          logger.info self.name.demodulize.to_s + ': ' + msg
        end
      end
      def self.log_error(msg)
        self.loggers.each do |logger|
          logger.error self.name.demodulize.to_s + ': ' + msg
        end
      end
      RUBY
    end
  end
end