class Admin::BudgetsWizard::GroupsImportsController < Admin::BudgetsWizard::BaseController
  include FeatureFlags

  MAX_FILE_SIZE = 5.megabytes
  EXTENSIONS = %w[.csv .tsv .txt].freeze

  feature_flag :budgets

  before_action :load_budget

  def create
    file = params[:file]

    if file.blank?
      flash.now[:error] = t("admin.budget_investments_imports.create.no_file")
    elsif EXTENSIONS.exclude?(File.extname(file.original_filename).downcase)
      flash.now[:error] = t("admin.budget_investments_imports.create.invalid_format")
    elsif file.size > MAX_FILE_SIZE
      flash.now[:error] = t("admin.budget_investments_imports.create.too_big",
                            size: helpers.number_to_human_size(MAX_FILE_SIZE))
    else
      @importer = Nairobi::WardsImporter.new(@budget, file.path).import
    end

    @groups = @budget.groups.order(:id)
    @group = @budget.groups.new
    render "admin/budgets_wizard/groups/index"
  end

  def template
    send_data Nairobi::WardsImporter.template, filename: "wards_template.csv", type: "text/csv"
  end

  private

    def load_budget
      @budget = Budget.find_by_slug_or_id! params[:budget_id]
    end
end
