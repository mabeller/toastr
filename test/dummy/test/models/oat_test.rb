require 'test_helper'

class OatTest < ActiveSupport::TestCase
  def setup
    @oat = Oat.create
    @wait_message = {'toastr' => { 'error' => 'Data not yet available' }}
  end

  # default expiration

  test 'default toast responds with waiting message on first run' do
    Rails.application.config.active_job.queue_adapter = :non_inline_queue_adapter
    assert_equal @wait_message, @oat.breakfast
  end

  test 'default toast responds with nonstale cache on first run if inline adapter' do
    Rails.application.config.active_job.queue_adapter = :inline
    assert_equal 'meal', @oat.breakfast['oat']
    assert_equal false, @oat.breakfast['toastr']['stale']
  end

  test 'default toast doesnt update toast if not stale' do
    @oat.breakfast
    updated_at = @oat.toasts.last.updated_at
    @oat.breakfast
    assert_equal updated_at, @oat.toasts.last.reload.updated_at
  end

  test 'default toast updates if stale' do
    Rails.application.config.active_job.queue_adapter = :inline
    first_response = @oat.breakfast
    assert_equal 'meal', first_response['oat']
    assert_equal false, first_response['toastr']['stale']

    updated_at = @oat.toasts.last.updated_at

    Rails.application.config.active_job.queue_adapter = :non_inline_queue_adapter
    @oat.touch
    second_response = @oat.breakfast # refreshes it
    assert_equal true, second_response['toastr']['stale']

    assert_not_equal updated_at, @oat.toasts.last.reload.updated_at
  end

  # expires_in toast

  test 'expires_in toast responds with waiting message on first run' do
    Rails.application.config.active_job.queue_adapter = :non_inline_queue_adapter
    assert_equal @wait_message, @oat.daily_report
  end

  test 'expires_in toast responds with stale cache on first run if inline adapter' do
    Rails.application.config.active_job.queue_adapter = :inline
    assert_equal 'result', @oat.daily_report['different']
    assert_equal false, @oat.daily_report['toastr']['stale']
  end

  test 'expires_in toast doesnt update toast if not stale' do
    @oat.daily_report
    updated_at = @oat.toasts.last.updated_at
    assert_equal 'result', @oat.daily_report['different']
    assert_equal updated_at, @oat.toasts.last.reload.updated_at
  end

  test 'expires_in toast updates if stale' do
    Rails.application.config.active_job.queue_adapter = :inline
    first_response = @oat.daily_report
    assert_equal 'result', first_response['different']
    assert_equal false, first_response['toastr']['stale']

    updated_at = @oat.toasts.last.updated_at

    Rails.application.config.active_job.queue_adapter = :non_inline_queue_adapter
    @oat.toasts.last.update_column :updated_at, 2.days.ago # 1.day is the expiration
    second_response = @oat.daily_report
    assert_equal 'result', second_response['different']
    assert_equal true, second_response['toastr']['stale']
    assert_not_equal updated_at, @oat.toasts.last.reload.updated_at
  end

  # arbitrary block toast

  test 'arbitrary block toast responds with waiting message on first run' do
    Rails.application.config.active_job.queue_adapter = :non_inline_queue_adapter
    assert_equal @wait_message, @oat.special
  end

  test 'arbitrary block toast responds with cache on first run if inline adapter' do
    Rails.application.config.active_job.queue_adapter = :inline
    assert_equal 'special', @oat.special['very']
    assert_equal false, @oat.special['toastr']['stale']
  end

  test 'arbitrary block toast doesnt update toast if not stale' do
    @oat.special
    @oat.update! created_at: '2015-01-01'
    updated_at = @oat.toasts.last.updated_at
    assert_equal 'special', @oat.special['very']
    assert_equal updated_at, @oat.toasts.last.reload.updated_at
  end

  test 'arbitrary block toast updates if stale' do
    Rails.application.config.active_job.queue_adapter = :inline
    first_response = @oat.special
    assert_equal 'special', first_response['very']
    assert_equal false, first_response['toastr']['stale']

    @oat.update! created_at: '2015-01-08'
    updated_at = @oat.toasts.last.updated_at

    Rails.application.config.active_job.queue_adapter = :non_inline_queue_adapter
    second_response = @oat.special
    assert_equal 'special', second_response['very']
    assert_equal true, second_response['toastr']['stale']
    assert_not_equal updated_at, @oat.toasts.last.reload.updated_at
  end
end
