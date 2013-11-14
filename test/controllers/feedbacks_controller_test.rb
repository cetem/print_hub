require 'test_helper'

class FeedbacksControllerTest < ActionController::TestCase
  test 'should create positive feedback' do
    assert_difference 'Feedback.count' do
      post :create, item: 'new_customer_help', score: 'positive'
    end

    assert_response :success
    assert_select '#unexpected_error', false
    assert_template 'feedbacks/positive'
  end

  test 'should create negative feedback' do
    assert_difference 'Feedback.count' do
      post :create, item: 'new_customer_help', score: 'negative'
    end

    assert_response :success
    assert_select '#unexpected_error', false
    assert_template 'feedbacks/negative'
  end

  test 'should update feedback' do
    feedback = Feedback.find(feedbacks(:needs_polishing).id)

    xhr :put, :update, id: feedback.to_param, feedback: {
      item: 'this_should_be_ignored',
      comments: 'It seems to me that needs polishing'
    }

    assert_response :success
    assert_select '#unexpected_error', false
    assert_template 'feedbacks/negative_comment'
    assert_equal 'It seems to me that needs polishing', feedback.reload.comments
    assert_not_equal 'this_should_be_ignored', feedback.reload.item
  end
end
