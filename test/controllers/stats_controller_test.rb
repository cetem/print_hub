require 'test_helper'

class StatsControllerTest < ActionController::TestCase
  def setup 
    UserSession.create(users(:operator))
  end
  test 'should get printers stats' do
    get :printers
    assert_response :success
    assert_not_nil assigns(:printers_count)
    assert_select '#unexpected_error', false
    assert_template 'stats/printers'
  end

  test 'should get filtered printers stats' do
    get :printers, interval: {
      from: 3.months.ago.to_datetime.to_s(:db),
      to: 1.day.from_now.to_datetime.to_s(:db)
    }
    assert_response :success
    assert_not_nil assigns(:printers_count)
    assert_equal 2, assigns(:printers_count).size
    assert_equal PrintJob.sum(:printed_pages), assigns(:printers_count).sum(&:second)
    assert_select '#unexpected_error', false
    assert_template 'stats/printers'
  end
  
  test 'should get filtered printers stats with 0 printed pages' do
    get :printers, interval: {
      from: 2.years.ago.to_datetime.to_s(:db),
      to: 1.year.ago.to_datetime.to_s(:db)
    }
    assert_response :success
    assert_not_nil assigns(:printers_count)
    assert_equal 0, assigns(:printers_count).size
    assert_equal 0, assigns(:printers_count).sum(&:second)
    assert_select '#unexpected_error', false
    assert_template 'stats/printers'
  end
  
  test 'should get filtered printers stats in csv' do
    get :printers, format: :csv, interval: {
      from: 3.months.ago.to_datetime.to_s(:db),
      to: 1.day.from_now.to_datetime.to_s(:db)
    }
    assert_response :success
    response = CSV.parse(@response.body)
    assert_not_nil response
    assert_equal 2, response.size
    assert_equal PrintJob.sum(:printed_pages), response.sum {|row| row[1].to_i}
  end
  
  test 'should get users stats' do
    get :users
    assert_response :success
    assert_not_nil assigns(:users_count)
    assert_select '#unexpected_error', false
    assert_template 'stats/users'
  end

  test 'should get filtered users stats' do
    get :users, interval: {
      from: 3.months.ago.to_datetime.to_s(:db),
      to: 1.day.from_now.to_datetime.to_s(:db)
    }
    assert_response :success
    assert_not_nil assigns(:users_count)
    assert_equal 2, assigns(:users_count).size
    assert_equal PrintJob.sum(:printed_pages), assigns(:users_count).sum(&:second)
    assert_select '#unexpected_error', false
    assert_template 'stats/users'
  end

  test 'should get filtered users stats with 0 printed pages' do
    get :users, interval: {
      from: 2.years.ago.to_datetime.to_s(:db),
      to: 1.year.ago.to_datetime.to_s(:db)
    }
    assert_response :success
    assert_not_nil assigns(:users_count)
    assert_equal 0, assigns(:users_count).size
    assert_equal 0, assigns(:users_count).sum(&:second)
    assert_select '#unexpected_error', false
    assert_template 'stats/users'
  end
  
  test 'should get filtered users stats in csv' do
    get :users, format: :csv, interval: {
      from: 3.months.ago.to_datetime.to_s(:db),
      to: 1.day.from_now.to_datetime.to_s(:db)
    }
    assert_response :success
    response = CSV.parse(@response.body)
    assert_not_nil response
    assert_equal 2, response.size
    assert_equal PrintJob.sum(:printed_pages), response.sum {|row| row[1].to_i}
  end
  
  test 'should get prints stats' do
    get :prints
    assert_response :success
    assert_not_nil assigns(:user_prints_count)
    assert_select '#unexpected_error', false
    assert_template 'stats/prints'
  end

  test 'should get filtered prints stats' do
    get :prints, interval: {
      from: 3.months.ago.to_datetime.to_s(:db),
      to: 1.day.from_now.to_datetime.to_s(:db)
    }
    assert_response :success
    assert_not_nil assigns(:user_prints_count)
    assert_equal 2, assigns(:user_prints_count).size
    assert_equal Print.count, assigns(:user_prints_count).sum(&:second)
    assert_select '#unexpected_error', false
    assert_template 'stats/prints'
  end

  test 'should get filtered prints stats with 0 printed pages' do
    get :prints, interval: {
      from: 2.years.ago.to_datetime.to_s(:db),
      to: 1.year.ago.to_datetime.to_s(:db)
    }
    assert_response :success
    assert_not_nil assigns(:user_prints_count)
    assert_equal 0, assigns(:user_prints_count).size
    assert_equal 0, assigns(:user_prints_count).sum(&:second)
    assert_select '#unexpected_error', false
    assert_template 'stats/prints'
  end
  
  test 'should get filtered prints stats in csv' do
    get :prints, format: :csv, interval: {
      from: 3.months.ago.to_datetime.to_s(:db),
      to: 1.day.from_now.to_datetime.to_s(:db)
    }
    assert_response :success
    response = CSV.parse(@response.body)
    assert_not_nil response
    assert_equal 2, response.size
    assert_equal Print.count, response.sum {|row| row[1].to_i}
  end
end
