namespace :nairobi do
  desc "Creates or updates the predefined milestone statuses for Nairobi projects"
  task milestone_statuses: :environment do
    Nairobi::ProjectsImporter.create_milestone_statuses
    puts "Milestone statuses: #{Milestone::Status.pluck(:name).join(", ")}"
  end

  desc "Permanently deletes the investments of a budget, or of all budgets if no budget is given"
  task :destroy_investments, [:budget_id] => :environment do |_, args|
    budget = Budget.find_by_slug_or_id!(args[:budget_id]) if args[:budget_id].present?
    destroyer = Nairobi::InvestmentsDestroyer.new(budget)
    scope = budget ? "budget \"#{budget.name}\"" : "ALL budgets"

    count = destroyer.count

    puts "Investments to delete in #{scope} (#{Rails.env}): #{count}"
    next puts("Nothing to delete") if count == 0

    unless ENV["CONFIRM"] == "yes"
      print "This cannot be undone. Type 'yes' to continue: "
      next puts("Cancelled") unless $stdin.gets.to_s.strip == "yes"
    end

    puts "Deleted investments: #{destroyer.destroy!}"
    puts "Remaining investments: #{Budget::Investment.with_hidden.count}"
  end

  desc "Imports Nairobi projects as winning investments: rake nairobi:import_projects[BUDGET_ID,CSV_PATH]"
  task :import_projects, [:budget_id, :path] => :environment do |_, args|
    budget = Budget.find_by_slug_or_id!(args[:budget_id])
    importer = Nairobi::ProjectsImporter.new(budget, args[:path]).import

    puts "Created: #{importer.created} | Updated: #{importer.updated}"
    puts "Headings total: #{budget.headings.count} | Investments: #{budget.investments.count}"
    puts "Warnings:", importer.warnings if importer.warnings.any?
    puts(importer.errors.any? ? ["Errors:", *importer.errors] : "No errors")
  end
end
