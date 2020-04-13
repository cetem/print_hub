ENV['RAILS_ENV'] = 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'authlogic/test_case'
require 'sidekiq/testing'
require 'database_cleaner'
# require 'minitest/reporters'
require 'capybara/rails'
require 'capybara/minitest'
require 'capybara-screenshot/minitest'
require 'capybara/poltergeist'

# Minitest::Reporters.use! Minitest::Reporters::ProgressReporter.new

class ActiveSupport::TestCase
  ActiveRecord::Migration.maintain_test_schema!
  set_fixture_class versions: PaperTrail::Version
  parallelize(workers: 1)

  # self.use_transactional_fixtures = true
  # Minitest::Reporters.use! Minitest::Reporters::ProgressReporter.new

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

  def pdf_test_file(file='test.pdf')
    process_for_upload(file, 'application/pdf')
  end

  def avatar_test_file
    process_for_upload('test.gif', 'image/gif')
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

  def process_for_upload(filename, content_type)
    Rack::Test::UploadedFile.new(
      Rails.root.join('test', 'fixtures', 'files', filename),
      content_type
    )
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
    print_jobs.map(&:copies).compact.sum
  end

  def drop_all_prints
    pdf_printer = ::CustomCups.pdf_printer
    return unless pdf_printer
    Thread.new { `lpstat -Wnot-completed -o | grep -i "#{pdf_printer}" | awk '{print $1}' | xargs cancel 2>&1` }
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

class JSException < Exception
  attr_reader :msgs

  def initialize(msgs)
    @msgs = msgs
  end

  def to_s
    "Js issue: \n #{msgs.join("\n")}"
  end
end

class ActionDispatch::IntegrationTest
  # Make the Capybara DSL available in all integration tests
  include Capybara::DSL
  include Capybara::Minitest::Assertions
  include Capybara::Screenshot::MiniTestPlugin

  # Transactional fixtures do not work with Selenium tests, because Capybara
  # uses a separate server thread, which the transactions would be hidden
  # from. We hence use DatabaseCleaner to truncate our test database.
  DatabaseCleaner.strategy = :truncation
  # Stop ActiveRecord from wrapping tests in transactions
  # self.use_transactional_fixtures = false

  RUN_WITH_GUI = ENV['local'] || false

  Capybara.server = :webrick
  Capybara.register_driver :poltergeist do |app|
    Capybara::Poltergeist::Driver.new(app, {
      inspector: true,
      js_errors: true,
      window_size: [1600, 1200]
    })
  end

  if ENV['TRAVIS']
    require 'jsonclient'
    require 'base64'

    Capybara::Screenshot.after_save_screenshot do |path|
      auth = { 'Authorization' => 'Bearer ' + "424871e2662f85351c735361fa763d7276b25518"}
      body = {image: Base64.encode64(File.read(path))}
      rsp = JSONClient.new.post('https://api.imgur.com/3/image', body, auth).body
      puts "\n======== IMG ========"
      puts "\n"
      puts rsp['data']['link']
      puts "\n"
      puts "\n"
    end
  end

  Capybara.javascript_driver = RUN_WITH_GUI ? :selenium : :poltergeist

  Capybara.current_driver = Capybara.javascript_driver
  Capybara.server_port = '5416' + (ENV['TEST_ENV_NUMBER'] || 9).to_s
  Capybara.default_max_wait_time = 3

  setup do
    Capybara.server_host = 'localhost'
    Capybara.app_host = "http://#{Capybara.server_host}:#{Capybara.server_port}"
    Capybara.reset!    # Forget the (simulated) browser state

    if RUN_WITH_GUI
      Capybara.page.driver.browser.manage.window.maximize
    else
      Capybara.page.driver.resize(1600, 1200)
    end
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
    # options = args.extract_options!
    # options[:user_id] ||= args.shift # if args.first.kind_of?(Symbol)
    # # options[:user_id] ||= users(:operator).id
    # options[:expected_path] ||= args.shift if args.first.is_a?(String)
    # options[:expected_path] ||= prints_path

    # user = options[:user_id].present? ? User.find(options[:user_id]) : users(:operator)
    # # UserSession.create(user)
    # page.driver.set_cookie(
    #   'user_credentials',
    #   "#{user.persistence_token}::#{user.id}"
    # )

    # visit root_path

    options = args.extract_options!
    options[:user_id] ||= args.shift # if args.first.kind_of?(Symbol)
    options[:user_id] ||= users(:operator).id
    options[:expected_path] ||= args.shift if args.first.is_a?(String)
    options[:expected_path] ||= prints_path

    visit new_user_session_path

    User.find(options[:user_id]).tap do |user|
      fill_in I18n.t('authlogic.attributes.user_session.username'),
        with: user.email
      fill_in I18n.t('authlogic.attributes.user_session.password'),
        with: "#{user.username}123"
    end

    click_button I18n.t('view.user_sessions.login')

    assert_page_has_no_errors!
    assert_equal options[:expected_path], current_path
  end

  def log_js_errors
    # unused
    errors = page.driver.browser.manage.logs.get(:browser)
    return unless errors

    puts errors
    parsed_errors = errors.map { |e| e if e.level == 'SEVERE' && message.present? }.compact
    raise JSException.new(parsed_errors) if parsed_errors
  end

  def wait_for_ajax
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop until finished_all_ajax_requests?
    end
  end

  def finished_all_ajax_requests?
    request_count = page.evaluate_script("$.active").to_i
    request_count && request_count.zero?
  rescue Timeout::Error
  end

  def fill_autocomplete_for(field, string)
    find(:css, "input[id^='#{field}']").native.send_keys(*string.each_char.to_a)
    wait_for_ajax
    sleep 1
    assert page.has_xpath?("//ul[contains(@class, 'ui-autocomplete')]", visible: true)
    find(:css, "input[id^='#{field}']").native.send_keys :down, :tab
  end
end
