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
    prepare_for_testing_non_meber_roles
  end

  def test_visible_for_non_member_watchers
    Role.non_member_watcher.update_attributes({
        :permissions => [:view_watched_issues]
    })
    assert_true @attachment.visible?(@watcher)
  end

  def test_not_visible_for_non_member_watchers
    Role.non_member_watcher.update_attributes({
        :permissions => []
    })
    assert_false @attachment.visible?(@watcher)
  end

  def test_visible_for_non_member_authors
    Role.non_member_author.update_attributes({
        :permissions => [:view_created_issues]
    })
    assert_true @attachment.visible?(@author)
  end

  def test_not_visible_for_non_member_authors
    Role.non_member_author.update_attributes({
        :permissions => []
    })
    assert_false @attachment.visible?(@author)
  end
end

