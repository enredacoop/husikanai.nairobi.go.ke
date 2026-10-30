require "rails_helper"

describe "Admin collaborative legislation", :admin do
  context "Create" do
    scenario "Valid legislation process" do
      visit admin_root_path

      within("#side_menu") do
        click_link "Topical Participation"
      end

      expect(page).not_to have_content "An example legislation process"

      click_link "New process"

      fill_in "Process Title", with: "An example legislation process"
      fill_in "Summary", with: "Summary of the process"
      fill_in "Description", with: "Describing the process"

      base_date = Date.current

      within "fieldset", text: "Draft phase" do
        check "Enabled"
        fill_in "Start", with: base_date - 3.days
        fill_in "End", with: base_date - 1.day
      end

      within_fieldset "Process" do
        fill_in "Start", with: base_date
        fill_in "End", with: base_date + 5.days
      end

      within_fieldset "Debate phase" do
        check "Enabled"
        fill_in "Start", with: base_date
        fill_in "End", with: base_date + 2.days
      end

      within_fieldset "Comments phase" do
        check "Enabled"
        fill_in "Start", with: base_date + 3.days
        fill_in "End", with: base_date + 5.days
      end

      check "legislation_process[draft_publication_enabled]"
      fill_in "Draft publication date", with: base_date + 3.days

      check "legislation_process[result_publication_enabled]"
      fill_in "Final result publication date", with: base_date + 7.days

      click_button "Create process"

      expect(page).to have_content "An example legislation process"
      expect(page).to have_content "Process created successfully"

      click_link "Click to visit"

      expect(page).to have_content "An example legislation process"
      expect(page).not_to have_content "Summary of the process"
      expect(page).to have_content "Describing the process"

      within(".legislation-process-list") do
        expect(page).to have_link text: "Debate"
        expect(page).to have_link text: "Comments"
      end

      visit legislation_processes_path

      expect(page).to have_content "An example legislation process"
      expect(page).to have_content "Summary of the process"
      expect(page).not_to have_content "Describing the process"
    end

    scenario "Legislation process in draft phase" do
      visit admin_root_path

      within("#side_menu") do
        click_link "Topical Participation"
      end

      expect(page).not_to have_content "An example legislation process"

      click_link "New process"

      fill_in "Process Title", with: "An example legislation process in draft phase"
      fill_in "Summary", with: "Summary of the process"
      fill_in "Description", with: "Describing the process"

      base_date = Date.current - 2.days

      within "fieldset", text: "Draft phase" do
        check "Enabled"
        fill_in "Start", with: base_date
        fill_in "End", with: base_date + 3.days
      end

      within_fieldset "Process" do
        fill_in "Start", with: base_date
        fill_in "End", with: base_date + 5.days
      end

      click_button "Create process"

      expect(page).to have_content "An example legislation process in draft phase"
      expect(page).to have_content "Process created successfully"

      click_link "Click to visit"

      expect(page).to have_content "An example legislation process in draft phase"
      expect(page).not_to have_content "Summary of the process"
      expect(page).to have_content "Describing the process"

      visit legislation_processes_path

      expect(page).not_to have_content "An example legislation process in draft phase"
      expect(page).not_to have_content "Summary of the process"
      expect(page).not_to have_content "Describing the process"
    end
  end

  context "Update" do
    before do
      create(:legislation_process,
             title: "An example legislation process",
             summary: "Summarizing the process",
             description: "Description of the process")
    end

    scenario "Remove summary text" do
      visit admin_root_path

      within("#side_menu") do
        click_link "Topical Participation"
      end

      within("tr", text: "An example legislation process") { click_link "Edit" }

      expect(page).to have_css "h2", text: "An example legislation process"
      expect(find("#legislation_process_debate_phase_enabled")).to be_checked
      expect(find("#legislation_process_published")).to be_checked

      fill_in "Summary", with: ""
      click_button "Save changes"

      expect(page).to have_content "Process updated successfully"

      visit legislation_processes_path
      expect(page).not_to have_content "Summarizing the process"
      expect(page).to have_content "Description of the process"
    end

    scenario "Deactivate draft publication" do
      visit admin_root_path

      within("#side_menu") do
        click_link "Topical Participation"
      end

      within("tr", text: "An example legislation process") { click_link "Edit" }

      expect(find("#legislation_process_draft_publication_enabled")).to be_checked

      uncheck "legislation_process_draft_publication_enabled"
      click_button "Save changes"

      expect(page).to have_content "Process updated successfully"
      expect(find("#debate_start_date").value).not_to be_blank
      expect(find("#debate_end_date").value).not_to be_blank

      click_link "Click to visit"

      expect(page).not_to have_content "Draft publication"
    end
  end
end
