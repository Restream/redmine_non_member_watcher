require File.expand_path('../../../../test_helper', __FILE__)

class RolePatchTest < ActiveSupport::TestCase
  fixtures :roles

  def test_allowed_to
    only_permissions = [
      :view_watched_issues,
      :view_watched_issues_list
    ]
    role             = Role.non_member_watcher
    role.permissions = only_permissions
    Role.non_member_watcher.save!
    Redmine::AccessControl.permissions.each do |perm|
      if only_permissions.include?(perm.name)
        assert_equal true, role.allowed_to?(perm.name), "Permission #{perm.name} should be allowed"
      else
        assert_equal false, role.allowed_to?(perm.name), "Permission #{perm.name} should not be allowed"
      end
    end
  end

  context '#non_member_watcher' do
    should 'return the non-member-watcher role' do
      role = Role.non_member_watcher
      assert role.builtin?
      assert_equal Role::BUILTIN_NON_MEMBER_WATCHER, role.builtin
    end

    context 'with a missing non-member-watcher role' do
      setup do
        Role.delete_all("builtin = #{Role::BUILTIN_NON_MEMBER_WATCHER}")
      end

      should 'create a new non-member-watcher role' do
        assert_difference('Role.count') do
          Role.non_member_watcher
        end
      end

      should 'return the non-member-watcher role' do
        role = Role.non_member_watcher
        assert role.builtin?
        assert_equal Role::BUILTIN_NON_MEMBER_WATCHER, role.builtin
      end
    end
  end

  context '#non_member_author' do
    should 'return the non-member-author role' do
      role = Role.non_member_author
      assert role.builtin?
      assert_equal Role::BUILTIN_NON_MEMBER_AUTHOR, role.builtin
    end

    context 'with a missing non-member-author role' do
      setup do
        Role.delete_all("builtin = #{Role::BUILTIN_NON_MEMBER_AUTHOR}")
      end

      should 'create a new non-member-author role' do
        assert_difference('Role.count') do
          Role.non_member_author
        end
      end

      should 'return the non-member-author role' do
        role = Role.non_member_author
        assert role.builtin?
        assert_equal Role::BUILTIN_NON_MEMBER_AUTHOR, role.builtin
      end
    end
  end

end

