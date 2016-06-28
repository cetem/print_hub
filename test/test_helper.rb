ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'authlogic/test_case'
require 'capybara/rails'
require 'sidekiq/testing'
require 'database_cleaner'
require "minitest/reporters"

Minitest::Reporters.use! Minitest::Reporters::ProgressReporter.new

class ActiveSupport::TestCase
  ActiveRecord::Migration.maintain_test_schema!
  set_fixture_class versions: PaperTrail::Version
  self.use_transactional_fixtures = true

  fixtures :all

  # Add more helper methods to be used by all tests here...

  def error_message_from_model(model, attribute, message, extra = {})
    ::ActiveModel::Errors.new(model).generate_message(attribute, message, extra)
  end

  def prepare_document_files
    Document.all.each { |document| link_file document.file.path, 'test.pdf' }
  end

  def prepare_avatar_files
    User.all.each { |user| link_file user.avatar.path, 'test.gif' }
  end

  def pdf_test_file
    process_with_action_dispatch('test.pdf', 'application/pdf')
  end

  def avatar_test_file
    process_with_action_dispatch('test.gif', 'image/gif')
  end

  def new_generic_operator(atributes = {})
    atributes[:name] ||= 'generic name'
    atributes[:last_name] ||= 'generic last name'
    atributes[:email] ||= 'generic_user@printhub.com'
    atributes[:default_printer] ||= ''
    atributes[:lines_per_page] ||= 12
    atributes[:language] ||= LANGUAGES.first.to_s
    atributes[:username] ||= 'generic_user'
    atributes[:password] ||= 'generic_user123'
    atributes[:password_confirmation] ||= 'generic_user123'
    atributes[:admin] ||= 'false'
    atributes[:enable] ||= true
    atributes[:avatar] ||= 'sample.png'
    atributes[:not_shifted] ||= false

    User.create! atributes
  end

  def new_generic_operator_with_avatar
    new_generic_operator(avatar: avatar_test_file)
  end

  private

  def process_with_action_dispatch(filename, content_type)
    ActionDispatch::Http::UploadedFile.new({
                                             filename: filename,
                                             content_type: content_type,
                                             tempfile:
      File.open( # Need File.open for path-method
        Rails.root.join('test', 'fixtures', 'files', filename)
      )
                                           })
  end

  def link_file(destiny_file, link_from)
    unless File.exist?(destiny_file)
      FileUtils.mkdir_p File.dirname(destiny_file)
      FileUtils.ln_s(
        Rails.root.join('test', 'fixtures', 'files', link_from),
        destiny_file
      )
    end
  end

  def job_count(print_jobs)
    print_jobs.map(&:copies).sum
  end

  def drop_all_prints
    `lpstat -Wnot-completed -o | grep -i "virtual" | awk '{print $1}' | xargs cancel`
  end
end

class ActionController::TestCase
  include Authlogic::TestCase
  setup :activate_authlogic
end

class ActiveSupport::TestCase
  include Authlogic::TestCase
  setup :activate_authlogic
end

class ActionDispatch::IntegrationTest
  # Make the Capybara DSL available in all integration tests
  include Capybara::DSL

  # Transactional fixtures do not work with Selenium tests, because Capybara
  # uses a separate server thread, which the transactions would be hidden
  # from. We hence use DatabaseCleaner to truncate our test database.
  DatabaseCleaner.strategy = :truncation
  # Stop ActiveRecord from wrapping tests in transactions
  self.use_transactional_fixtures = false

  Capybara.register_driver :chrome do |app|
    Capybara::Selenium::Driver.new(app, :browser => :chrome)
  end

  setup do
    Capybara.javascript_driver = ENV['USE_CHROME'] ? :chrome : :selenium
    Capybara.current_driver = Capybara.javascript_driver # :selenium by default
    Capybara.server_port = '54163'
    Capybara.app_host = 'http://localhost:54163'
    Capybara.reset!    # Forget the (simulated) browser state
    Capybara.default_max_wait_time = 4
  end

  teardown do
    DatabaseCleaner.clean       # Truncate the database
    Capybara.reset!             # Forget the (simulated) browser state
  end

  def assert_page_has_no_errors!
    sleep 0.5
    assert page.has_no_css?('#unexpected_error')
  end

  def show_collapse_menu_if_needed
    collapse_css = 'a[data-toggle="collapse"]'

    if page.has_css?(collapse_css) && find(collapse_css).visible?
      find(collapse_css).click
    end
  end

  def login(*args)
    options = args.extract_options!

    options[:user_id] ||= args.shift # if args.first.kind_of?(Symbol)
    options[:user_id] ||= users(:operator).id
    options[:expected_path] ||= args.shift if args.first.is_a?(String)
    options[:expected_path] ||= prints_path

    visit new_user_session_path

    assert_page_has_no_errors!

    User.find(options[:user_id]).tap do |user|
      fill_in I18n.t('authlogic.attributes.user_session.username'),
              with: user.email
      fill_in I18n.t('authlogic.attributes.user_session.password'),
              with: "#{user.username}123"
    end

    click_button I18n.t('view.user_sessions.login')

    assert_page_has_no_errors!
    assert_equal options[:expected_path], current_path

    show_collapse_menu_if_needed
  end
end
