class SettingsController < ApplicationController
  before_filter :require_admin_user
  
  # GET /settings
  # GET /settings.json
  def index
    @title = t('view.settings.index_title')
    @settings = Setting.order('created_at ASC').paginate(
      page: params[:page], per_page: lines_per_page
    )

    respond_to do |format|
      format.html # index.html.erb
      format.json  { render json: @settings }
    end
  end

  # GET /settings/var_name
  # GET /settings/var_name.json
  def show
    @title = t('view.settings.show_title')
    @setting = Setting.find_by_var(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json  { render json: @setting }
    end
  end

  # GET /settings/var_name/edit
  def edit
    @title = t('view.settings.edit_title')
    @setting = Setting.find_by_var(params[:id])
  end

  # PUT /settings/var_name
  # PUT /settings/var_name.json
  def update
    @title = t('view.settings.edit_title')
    @setting = Setting.find_by_var(params[:id])

    respond_to do |format|
      if @setting.update_attributes(params[:setting])
        format.html { redirect_to(settings_url, notice: t('view.settings.correctly_updated')) }
        format.json  { head :ok }
      else
        format.html { render action: 'edit' }
        format.json  { render json: @setting.errors, status: :unprocessable_entity }
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t('view.settings.stale_object_error')
    redirect_to edit_setting_url(@setting)
  end
end