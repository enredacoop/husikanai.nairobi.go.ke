require "rails_helper"

describe "Admin geozones", :admin do
  scenario "Show polygons when a heading is associated with a geozone" do
    Setting["feature.map"] = true
    geojson = <<~JSON
      {
        "type": "Feature",
        "geometry": {
          "type": "Polygon",
          "coordinates": [[[-0.1, 51.5], [-0.2, 51.4], [-0.3, 51.6], [-0.1, 51.5]]]
        }
      }
    JSON

    geozone = create(:geozone, name: "Polygon me!")
    budget = create(:budget)
    group = create(:budget_group, budget: budget)
    heading = create(:budget_heading, name: "Area 51", group: group)

    visit edit_admin_geozone_path(geozone)
    fill_in "GeoJSON data (optional)", with: geojson
    fill_in "Color (optional)", with: "#f5c211"
    click_button "Save changes"

    expect(page).to have_content "Geozone updated successfully"

    visit edit_admin_budget_group_heading_path(budget, group, heading)
    select "Polygon me!", from: "Scope of operation"

    click_button "Save ward"

    expect(page).to have_content "Ward updated successfully"

    visit budget_path(budget)

    expect(page).to have_css ".map-polygon[fill='#f5c211']"
    within(".map-location") { expect(page).not_to have_link "Area 51" }

    find(".map-polygon").click

    within ".map-location" do
      expect(page).to have_link "Area 51", href: budget_investments_path(budget, heading_id: heading.id)
    end
  end
end
