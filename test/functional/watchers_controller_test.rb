require File.expand_path('../../test_helper', __FILE__)
require 'watchers_controller'

# Re-raise errors caught by the controller.
class WatchersController; def rescue_action(e) raise e end; end

class WatchersControllerTest < ActionController::TestCase
  fixtures :projects, :users, :members, :member_roles, :roles,
           :groups_users,
           :trackers, :projects_trackers,
           :enabled_modules,
           :versions,
           :issue_statuses, :issue_categories, :issue_relations, :workflows,
           :enumerations,
           :issues

  def setup
    @issue = Issue.find(1)

    @project = @issue.project

    # make project private
    @project.is_public = false
    @project.save!

    # non_member for issue project
    @watcher = User.find(4)

    @issue.add_watcher(@watcher)

    @controller = WatchersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = @watcher
    setup_non_member_watcher_role
  end

  def test_unwatch_for_non_member_watcher
    @request.session[:user_id] = @watcher.id
    xhr :post, :unwatch, :object_type => 'issue', :object_id => @issue.id
    assert_response :success
    @issue.reload
    assert_false @issue.watched_by?(@watcher)
  end
end
