require 'plutolib/logger_utils'

class Plutolib::Mailchimper
  include Plutolib::LoggerUtils

  def subscribe(args)
    args ||= {}
    name = args[:name] || ''
    first_name, last_name = name.split(' ', 2)
    last_name ||= ''
    email = args[:email]
    mailchimp_api_key = args[:api_key] || AppConfig.mailchimp_api_key
    mailchimp_list_id = args[:list_id] || AppConfig.mailchimp_list_id

    if email.blank? or !Rails.env.production? or !mailchimp_api_key.present?
      false
    else
      begin
        with_retries do
          batch = [ { :EMAIL => email, :EMAIL_TYPE => 'html', :FNAME => first_name, :LNAME => last_name } ]
          # listBatchSubscribe(string apikey, string id, array batch, boolean double_optin, boolean update_existing, boolean replace_interests)
          h = Hominid::API.new(mailchimp_api_key)
          h.listBatchSubscribe(mailchimp_list_id, batch, false, false, true)
        end
      rescue => exc
        log_error "Unexpected mailchimp exception: #{exc.class.name} #{exc.message}:\n" + exc.backtrace.join("\n")
        return false
      end
      true
    end
  end
  
  MAX_RETRIES=3
  def with_retries(&block)
    attempts = 0
    while ((attempts += 1) <= MAX_RETRIES)
      begin
        return yield
      rescue EOFError
        if attempts == MAX_RETRIES
          log_error "Timeout on attempt #{attempt}.  Giving up..."
          raise $!
        else
          log_error "Timeout on attempt #{attempt}.  Retrying..."
        end
      rescue
        raise $!
      end
    end
  end
  
end