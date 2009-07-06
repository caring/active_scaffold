# wrap find_template to search in ActiveScaffold paths when template is missing
module ActionView #:nodoc:
  class PathSet
    attr_accessor :active_scaffold_paths
    attr_accessor :active_scaffold_override_paths
    attr_accessor :controller_path

    def find_template_with_active_scaffold(original_template_path, format = nil, html_fallback = true)
      begin
        find_template_without_active_scaffold(original_template_path, format, html_fallback)
      rescue MissingTemplate => e
        if active_scaffold_paths && original_template_path.include?('/')
          begin
            active_scaffold_paths.find_template_without_active_scaffold(original_template_path.split('/').last, format, html_fallback)
          rescue MissingTemplate
            if active_scaffold_override_paths && original_template_path.starts_with?(controller_path)
              path = original_template_path[(controller_path.length+1)..-1]
              raise e unless path.starts_with?("_")
              active_scaffold_override_paths.find_template_without_active_scaffold(path, format, html_fallback)
            else
              raise e
            end
          end
        else
          raise e
        end
      end
    end
    alias_method_chain :find_template, :active_scaffold
  end
end

module ActionController #:nodoc:
  class Base
    def assign_names_with_active_scaffold
      assign_names_without_active_scaffold
      if search_generic_view_paths?
        @template.view_paths.active_scaffold_paths = self.class.active_scaffold_paths
        @template.view_paths.controller_path = self.class.controller_path
        @template.view_paths.active_scaffold_override_paths = self.class.active_scaffold_override_paths
      end
    end
    alias_method_chain :assign_names, :active_scaffold

    def search_generic_view_paths?
      !self.is_a?(ActionMailer::Base) && self.class.action_methods.include?(self.action_name)
    end
  end
end
