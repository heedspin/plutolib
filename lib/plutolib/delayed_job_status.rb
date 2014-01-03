require 'plutolib/active_hash_methods'
module Plutolib
  class DelayedJobStatus < ActiveHash::Base
    self.data = [
      {:id => 1, :name => 'Queued'},
      {:id => 2, :name => 'Running'},
      {:id => 3, :name => 'Complete'},
      {:id => 4, :name => 'Error'},
      {:id => 5, :name => 'Stopping'},
      {:id => 6, :name => 'Stopped'}
    ]
    include Plutolib::ActiveHashMethods
    
    def in_progress?
      self.queued? || self.running?
    end
  end
end