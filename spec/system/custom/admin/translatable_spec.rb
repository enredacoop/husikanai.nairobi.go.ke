require "rails_helper"

describe "Admin edit translatable records", :admin do
  before do
    translatable.main_link_url = "https://consuldemocracy.org" if translatable.is_a?(Budget::Phase)
    translatable.update!(attributes)
  end

  let(:fields) { translatable.translated_attribute_names }

  let(:attributes) do
    fields.product(%i[en es]).to_h do |field, locale|
      [:"#{field}_#{locale}", text_for(field, locale)]
    end
  end

  context "Add a translation" do
    context "Input fields" do
      let(:translatable) { create(:budget_heading) }
      let(:path) { admin_polymorphic_path(translatable, action: :edit) }

      scenario "Maintains existing translations" do
        visit path

        select "Français", from: "Add language"
        fill_in "Ward name", with: "Nom en Français"
        click_button "Save ward"

        expect(page).to have_content "Ward updated successfully"

        visit path

        expect(page).to have_field "Ward name", with: "Ward name in English"

        select "Español", from: "Current language"

        expect(page).to have_field "Ward name", with: "Nombre del barrio en español"

        select "Français", from: "Current language"

        expect(page).to have_field "Ward name", with: "Nom en Français"
      end
    end
  end

  context "Remove a translation" do
    let(:translatable) { create(:budget_group) }
    let(:path) { edit_admin_budget_group_path(translatable.budget, translatable) }

    scenario "Keeps the other languages" do
      visit path

      select "Español", from: "Current language"
      click_link "Remove language"

      expect(page).not_to have_select "Current language", with_options: ["Español"]

      click_button "Save subcounty"

      expect(page).to have_content "Subcounty updated successfully"

      visit path

      expect(page).to have_select "Current language", with_options: ["English"]
      expect(page).not_to have_select "Current language", with_options: ["Español"]
    end
  end

  context "Current locale translation does not exist" do
    context "For Budget::Phase" do
      let(:translatable) { create(:budget).phases.last }

      scenario "Shows first available fallback" do
        translatable.update!({ name_fr: "Name en Français", description_fr: "Phase en Français" })

        visit edit_admin_budget_budget_phase_path(translatable.budget, translatable)

        select "English", from: "Current language"
        click_link "Remove language"
        select "Español", from: "Current language"
        click_link "Remove language"

        click_button "Save changes"

        expect(page).to have_content "Changes saved"

        visit budget_path(translatable.budget)
        click_link "Name en Français"

        expect(page).to have_content "Phase en Français"
      end
    end
  end
end
