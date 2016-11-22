Deface::Override.new(
  virtual_path:     'roles/_form',
  name:             'remove_non_members_issues_visibility',
  surround:         "erb[silent]:contains('unless @role.anonymous?')",
  closing_selector: "erb[silent]:contains('end')",
  text:             '<% unless @role.non_member_watcher? || @role.non_member_author? %><%= render_original %><% end %>')
