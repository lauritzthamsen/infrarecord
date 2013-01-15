module Infrarecord
  class Engine < Rails::Engine
    engine_name :infrarecord

    initializer 'infrarecord.active_record_monkey_patch', :after=> :disable_dependency_loading do |app|
      require 'infrarecord/active_record_monkey_patch'
      Rails.application.eager_load! # is this the right place?
    end
  end
end
