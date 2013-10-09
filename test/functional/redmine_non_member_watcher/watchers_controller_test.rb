require File.expand_path('../../../test_helper', __FILE__)
require 'watchers_controller'

# Re-raise errors caught by the controller.
class WatchersController; def rescue_action(e) raise e end; end

class RedmineNonMemberWatcher::WatchersControllerTest < ActionController::TestCase
  fixtures :projects, :users, :members, :member_roles, :roles,
           :groups_users,
           :trackers, :projects_trackers,
           :enabled_modules,
           :versions,
           :issue_statuses, :issue_categories, :issue_relations, :workflows,
           :enumerations,
           :issues, :attachments

  def setup
    prepare_for_testing_non_meber_roles
    @controller = WatchersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_unwatch_for_non_member_watcher
    role = Role.non_member_watcher
    role.permissions = [:view_watched_issues]
    role.save!
    User.current = @watcher
    @request.session[:user_id] = @watcher.id
    xhr :post, :unwatch, :object_type => 'issue', :object_id => @issue.id
    assert_response :success
    @issue.reload
    assert_equal false, @issue.watched_by?(@watcher)
  end
end
