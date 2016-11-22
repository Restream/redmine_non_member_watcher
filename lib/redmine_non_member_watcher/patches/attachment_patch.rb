require_dependency 'attachment'

module RedmineNonMemberWatcher::Patches
  module AttachmentPatch
    extend ActiveSupport::Concern

    included do
      alias_method_chain :visible?, :non_member_roles
    end

    # Issue may be visible when project is not
    def visible_with_non_member_roles?(user = User.current)
      visible_without_non_member_roles?(user) || (
      user.logged? &&
        container &&
        container.is_a?(Issue) &&
        container.visible?(user))
    end
  end
end
