require 'test_helper'

class FilesControllerTest < ActionController::TestCase
  setup do
    @document = documents(:math_book)
    @operator = users(:operator)

    prepare_document_files
    prepare_avatar_files
  end

  test 'should download avatar' do
    sign_in(@operator)

    get :download, params: { path: drop_private_dir(@operator.avatar.path) }
    assert_response :success
    assert_equal(
      File.open(@operator.reload.avatar.path, encoding: 'ASCII-8BIT').read,
      @response.body
    )
  end

  test 'should download document' do
    sign_in(@operator)

    get :download, params: { path: drop_private_dir(@document.file.path) }
    assert_response :success
    assert_equal(
      File.open(@document.reload.file.path, encoding: 'ASCII-8BIT').read,
      @response.body
    )
  end

  test 'should not download document' do
    sign_in(@operator)

    file = @document.file.path

    FileUtils.rm file if File.exist?(file)

    assert !File.exist?(file)
    get :download, params: { path: drop_private_dir(file) }
    assert_redirected_to prints_url
    assert_equal I18n.t('view.documents.non_existent'), flash.notice
  end

  test 'should download barcode' do
    sign_in(@operator)

    get :download_barcode, params: { code: @document.code }
    assert_response :success
    # assert_select '#unexpected_error', false
    assert_equal 'image/png', @response.content_type
  end

  test 'should download barcode of new document' do
    sign_in(@operator)

    get :download_barcode, params: { code: '159321' }
    assert_response :success
    # assert_select '#unexpected_error', false
    assert_equal 'image/png', @response.content_type
  end

  test 'should not download original document' do
    CustomerSession.create(customers(:student))

    assert File.exist?(@document.file.path)
    get :download, params: { path: drop_private_dir(@document.file.path) }
    assert_redirected_to catalog_url
    assert_equal I18n.t('view.documents.non_existent'), flash.notice
  end

  test 'should not download document thumb if no exist' do
    CustomerSession.create(customers(:student))

    file = @document.file.pdf_thumb.path
    FileUtils.rm file if File.exist?(file)

    assert !File.exist?(file)
    get :download, params: { path: drop_private_dir(file) }
    assert_redirected_to catalog_url
    assert_equal I18n.t('view.documents.non_existent'), flash.notice
  end

  test 'should not download avatar' do
    sign_in(@operator)

    file = @operator.avatar.path

    FileUtils.rm file if File.exist?(file)

    assert !File.exist?(file)
    get :download, params: { path: drop_private_dir(file) }
    assert_redirected_to users_url
    assert_equal I18n.t('view.users.non_existent_avatar'), flash.notice
  end

  private

  def drop_private_dir(path)
    path.sub("#{PRIVATE_PATH}/", '')
  end
end
