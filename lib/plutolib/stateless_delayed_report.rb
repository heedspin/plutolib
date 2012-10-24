require 'plutolib/logger_utils'

module Plutolib::StatelessDelayedReport
  def self.included(base)
    base.class_eval <<-RUBY
      include Plutolib::LoggerUtils
      attr_accessor :delayed_job_method
    RUBY
  end

  def run_in_background!(method_to_run=nil)
    if self.respond_to?(:delayed_job_method=)
      self.delayed_job_method = method_to_run
    else
      @delayed_job_method = method_to_run
    end
    self.delay.delayed_job_main
  end

  def delayed_job_main
    method_to_run = if self.respond_to?(:delayed_job_method)
      self.delayed_job_method
    else
      @delayed_job_method
    end
    method_to_run ||= :run_report
    begin
      log "Starting #{method_to_run}"
      self.send(method_to_run)
      log "Finished #{method_to_run}"
      true
    rescue Exception => exc
      log_exception exc
      raise exc
    rescue => exc
      log_exception exc
      raise exc
    end
  end
  
  def run_report
    log "Implement me!"
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
