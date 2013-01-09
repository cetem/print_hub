ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'authlogic/test_case'
require 'capybara/rails'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...

  set_fixture_class bonuses: 'Bonus'

  def error_message_from_model(model, attribute, message, extra = {})
    ::ActiveModel::Errors.new(model).generate_message(attribute, message, extra)
  end

  def prepare_document_files
    Document.all.each do |document|
      unless File.exists?(document.file.path)
        FileUtils.mkdir_p File.dirname(document.file.path)
        FileUtils.ln_s(
          File.join(Rails.root, 'test', 'fixtures', 'files', 'test.pdf'),
          document.file.path
        )
      end
    end
  end
  
  def prepare_avatar_files
    User.all.each do |user|
      unless File.exists?(user.avatar.path)
        FileUtils.mkdir_p File.dirname(user.avatar.path)
        FileUtils.ln_s(
          File.join(Rails.root, 'test', 'fixtures', 'files', 'test.gif'),
          user.avatar.path
        )
      end
    end
  end

  def prepare_settings
    Setting.price_per_one_sided_copy = '0.10'
    Setting.price_per_two_sided_copy = '0.07'
  end

  def pdf_test_file_processed_with_action_dispatch
    Rack::Test::UploadedFile.new(
      File.join(Rails.root, 'test', 'fixtures', 'files', 'test.pdf')
    )
  end
end

class ActionController::TestCase
  setup :activate_authlogic
end

class ActiveSupport::TestCase
  setup :activate_authlogic
end

# Transactional fixtures do not work with Selenium tests, because Capybara
# uses a separate server thread, which the transactions would be hidden
# from. We hence use DatabaseCleaner to truncate our test database.
DatabaseCleaner.strategy = :truncation

class ActionDispatch::IntegrationTest
  # Make the Capybara DSL available in all integration tests
  include Capybara::DSL

  # Stop ActiveRecord from wrapping tests in transactions
  self.use_transactional_fixtures = false

  teardown do
    DatabaseCleaner.clean       # Truncate the database
    Capybara.reset_sessions!    # Forget the (simulated) browser state
    Capybara.use_default_driver # Revert Capybara.current_driver to Capybara.default_driver
  end
  
  def assert_page_has_no_errors!
    assert page.has_no_css?('#unexpected_error')
  end

  def login(*args)
    options = args.extract_options!
    
    options[:user_id] ||= args.shift if args.first.kind_of?(Symbol)
    options[:user_id] ||= :administrator
    options[:expected_path] ||= args.shift if args.first.kind_of?(String)
    options[:expected_path] ||= prints_path

    visit new_user_session_path

    assert_page_has_no_errors!

    users(options[:user_id]).tap do |user|
      fill_in I18n.t('authlogic.attributes.user_session.username'),
        with: user.email
      fill_in I18n.t('authlogic.attributes.user_session.password'),
        with: "#{user.username}123"
    end

    click_button I18n.t('view.user_sessions.login')
    
    assert_page_has_no_errors!
    assert_equal options[:expected_path], current_path
  end
end
