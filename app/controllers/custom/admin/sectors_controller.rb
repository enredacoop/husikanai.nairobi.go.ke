class Admin::SectorsController < Admin::BaseController
  include FeatureFlags

  feature_flag :budgets

  before_action :load_sector, only: [:edit, :update, :destroy]

  def index
    @sectors = Sector.main.includes(:sub_sectors)
  end

  def new
    @sector = Sector.new(parent_id: params[:parent_id])
  end

  def create
    @sector = Sector.new(sector_params)

    if @sector.save
      redirect_to admin_sectors_path, notice: t("admin.sectors.create.notice")
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @sector.update(sector_params)
      redirect_to admin_sectors_path, notice: t("admin.sectors.update.notice")
    else
      render :edit
    end
  end

  def destroy
    if @sector.destroy
      redirect_to admin_sectors_path, notice: t("admin.sectors.destroy.notice")
    else
      redirect_to admin_sectors_path, alert: t("admin.sectors.destroy.unable_notice")
    end
  end

  private

    def load_sector
      @sector = Sector.find(params[:id])
    end

    def sector_params
      params.require(:sector).permit(:name, :parent_id)
    end
end
