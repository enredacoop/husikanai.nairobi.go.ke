module Budgets
  # The boroughs, subcounties and wards section of the admin budget page is folded on page load
  def open_groups_and_headings
    find("summary", text: "Boroughs, subcounties and wards").click
  end
end
