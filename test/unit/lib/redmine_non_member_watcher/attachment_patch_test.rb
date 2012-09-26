require File.expand_path('../../../../test_helper', __FILE__)

class AttachmentPatchTest < ActiveSupport::TestCase
  fixtures :projects, :users, :members, :member_roles, :roles,
           :groups_users,
           :trackers, :projects_trackers,
           :enabled_modules,
           :versions,
           :issue_statuses, :issue_categories, :issue_relations, :workflows,
           :enumerations,
           :issues, :attachments

  def setup
    @issue = Issue.find(1)
    @attachment = Attachment.find(1)
    @attachment.container = @issue
    @attachment.save!

    @project = @issue.project

    # make project private
    @project.is_public = false
    @project.save!

    # non_member for issue project
    @watcher = User.find(4)

    @issue.add_watcher(@watcher)
  end

  def test_visible_for_non_member_watchers
    role = Role.non_member_watcher
    role.permissions = [:view_watched_issues]
    role.save!
    assert @attachment.visible?(@watcher)
  end
end

