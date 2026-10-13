class Admin::BudgetsWizard::Groups::ImportComponent < ApplicationComponent
  attr_reader :budget, :importer

  def initialize(budget, importer)
    @budget = budget
    @importer = importer
  end

  private

    def columns
      Nairobi::WardsImporter::COLUMNS.join(",")
    end
end
