require "rails_helper"

describe "Admin legislation draft versions", :admin do
  context "Create" do
    scenario "Valid legislation draft version" do
      create(:legislation_process, title: "An example legislation process")

      visit admin_root_path

      within("#side_menu") do
        click_link "Collaborative Policy and Legislation"
      end

      within("tr", text: "An example legislation process") { click_link "Edit" }
      click_link "Drafting"

      click_link "Create version"

      fill_in "Version title", with: "Version 3"
      fill_in "Changes", with: "Version 3 changes"
      fill_in_markdown_editor "Text", with: "Version 3 body"

      within("form .end") do
        click_button "Create version"
      end

      expect(page).to have_content "An example legislation process"
      expect(page).to have_content "Version 3"
    end
  end

  context "Update" do
    scenario "Valid legislation draft version" do
      process = create(:legislation_process, title: "An example legislation process")
      create(:legislation_draft_version, title: "Version 1", process: process)

      visit admin_root_path

      within("#side_menu") do
        click_link "Collaborative Policy and Legislation"
      end

      click_link "All"

      expect(page).not_to have_link "All"

      within("tr", text: "An example legislation process") { click_link "Edit" }
      click_link "Drafting"

      click_link "Version 1"

      fill_in "Version title", with: "Version 1b"
      fill_in_markdown_editor "Text", with: "# Version 1 body\r\n\r\nParagraph\r\n\r\n>Quote"

      click_button "Save changes"

      expect(page).to have_content "Version 1b"
    end
  end
end
