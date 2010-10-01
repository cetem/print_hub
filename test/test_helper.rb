ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'authlogic/test_case'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...

  def error_message_from_model(model, attribute, message, extra = {})
    ::ActiveModel::Errors.new(model).generate_message(attribute, message, extra)
  end

  def prepare_document_files
    Document.all.each do |document|
      unless File.exists?(document.file.path)
        FileUtils.mkdir_p File.dirname(document.file.path)
        FileUtils.cp File.join(Rails.root, 'test', 'fixtures', 'files', 'test.pdf'),
          document.file.path
      end
    end
  end
end

class ActionController::TestCase
  setup :activate_authlogic
end