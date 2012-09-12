require 'plutolib/logger_utils'
require 'plutolib/delayed_job_status'

module Plutolib::StatefulDelayedReport
  def self.included(base)
    base.class_eval <<-RUBY
      include Plutolib::LoggerUtils
      belongs_to :delayed_job, :class_name => 'Delayed::Backend::ActiveRecord::Job'
      before_save :save_string_logger
      extend ActiveHash::Associations::ActiveRecordExtensions
      belongs_to_active_hash :delayed_job_status, :class_name => 'Plutolib::DelayedJobStatus'
      attr_accessor :delayed_method_to_run
    RUBY
  end
  
  def run_in_background!(method_to_run=nil)
    if self.respond_to?(:delayed_job_method)
      self.delayed_job_method = method_to_run
    end
    self.delayed_job_status = Plutolib::DelayedJobStatus.queued
    # This logic is suspicious.  Either always save or always update columns?
    if self.new_record? or self.delayed_job_method
      self.save
    else
      self.set_delayed_job_status!
    end
    if delayed_job = self.delay.delayed_job_main
      self.delayed_job_id = delayed_job.id
      self.update_column(:delayed_job_id, delayed_job.id)
    end
  end

  def run_report
    log "#{self.report_name} does nothing and does it beautifully!"
  end  
  
  def report_name
    "#{self.class.name.demodulize.titleize} #{self.id}"
  end

  def set_delayed_job_status(status=nil)
    self.delayed_job_status = status
    self.delayed_job_status_id = status.try(:id)
  end
  
  def set_delayed_job_status!(status=nil)
    if status.nil? or self.delayed_job_status != status
      self.delayed_job_status = status if status
      self.update_column(:delayed_job_status_id, self.delayed_job_status.id)  
    end
  end
  
  def delayed_job_main
    return if self.delayed_job_status.try(:complete?)
    method_to_run = if self.respond_to?(:delayed_job_method)
      self.delayed_job_method
    end
    method_to_run ||= :run_report
    begin
      self.set_delayed_job_status! Plutolib::DelayedJobStatus.running
      self.delayed_job_log = nil
      self.loggers.push self.string_logger
      log "#{self.report_name} Starting"
      self.send(method_to_run)
      self.set_delayed_job_status(Plutolib::DelayedJobStatus.complete) if self.delayed_job_status.try(:running?)
      log "#{self.report_name} Finished with status #{self.delayed_job_status}"
      self.save
    rescue => exc
      backtrace = exc.respond_to?(:backtrace) ? exc.backtrace : []
      error_title = "#{self.report_name} exception: #{exc.class.name}: #{exc.message}"
      log "#{error_title}\n" + backtrace.join("\n")
      self.set_delayed_job_status Plutolib::DelayedJobStatus.error
      self.save
      self.hopthetoad(error_title, backtrace)
      raise exc
    end    
  end
  
  def hopthetoad(error_title, backtrace=nil)
    if Rails.env.production?
      Airbrake.notify :error_class => self.report_name, :error_message => error_title, :backtrace => backtrace
    end
  end

  def string_logger
    @string_logger ||= Logger.new(self.string_logger_buffer)
  end
  
  def truncate_string_logger_buffer
    self.string_logger_buffer.rewind
    txt = self.string_logger_buffer.read
    self.string_logger_buffer.rewind
    self.string_logger_buffer.truncate(0)
    txt
  end
  
  def string_logger_buffer
    @string_logger_buffer ||= StringIO.new
  end
  
  def save_string_logger
    txt = self.truncate_string_logger_buffer
    if txt.present?
      self.delayed_job_log = (self.delayed_job_log || '') + txt
      # logger.info txt
    end
  end
  
  def should_stop?
    self.reload
    self.push_status.stopped? || SignalHandler.instance.shutdown?
  end
  
end
