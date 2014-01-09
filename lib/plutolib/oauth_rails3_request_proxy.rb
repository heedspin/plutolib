require 'active_support'
require 'action_controller'
require 'uri'

module Plutolib
    class OauthRails3RequestProxy < OAuth::RequestProxy::Base
    # proxies(defined?(ActionController::AbstractRequest) ? ActionController::AbstractRequest : ActionController::Request)

    def method
      request.method.to_s.upcase
    end

    def uri
      request.url
    end

    def parameters
      if options[:clobber_request]
        options[:parameters] || {}
      else
        params = request_params.merge(query_params).merge(header_params)
        params.stringify_keys! if params.respond_to?(:stringify_keys!)
        params.merge(options[:parameters] || {})
      end
    end

    # Override from OAuth::RequestProxy::Base to avoid roundtrip
    # conversion to Hash or Array and thus preserve the original
    # parameter names
    def parameters_for_signature
      params = []
      params << options[:parameters].to_query if options[:parameters]

      unless options[:clobber_request]
        params << header_params.to_query
        params << request.query_string unless query_string_blank?

        if request.post? && request.content_type.to_s.downcase.start_with?("application/x-www-form-urlencoded")
          params << request.raw_post
        end
      end

      params.
        join('&').split('&').
        reject(&:blank?).
        map { |p| p.split('=').map{|esc| CGI.unescape(esc)} }.
        reject { |kv| kv[0] == 'oauth_signature'}
    end

    def query_string_blank?
      if uri = request.url
        uri.split('?', 2)[1].nil?
      else
        request.query_string.blank?
      end
    end



  protected

    def query_params
      request.query_parameters
    end

    def request_params
      request.request_parameters
    end

  end
end