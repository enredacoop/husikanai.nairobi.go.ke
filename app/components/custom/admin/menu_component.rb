class Admin::MenuComponent < ApplicationComponent; end

load Rails.root.join("app", "components", "admin", "menu_component.rb")

class Admin::MenuComponent
  private

    alias_method :consul_default_links, :default_links

    def default_links
      links = consul_default_links
      budgets_index = links.index { |link| link.is_a?(Array) && link.last.try(:[], :class) == "budgets-link" }

      budgets_index ? links.insert(budgets_index + 1, sectors_link) : links
    end

    def sectors_link
      [
        t("admin.menu.sectors"),
        admin_sectors_path,
        controller_name == "sectors",
        class: "sectors-link"
      ]
    end
end
