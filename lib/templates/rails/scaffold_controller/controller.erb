<% module_namespacing do -%>
class <%= controller_class_name %>Controller < ApplicationController
  before_action :set_<%= singular_table_name %>, only:  [:show, :edit, :update, :destroy]

  # GET <%= route_url %>
  def index
    @title = t('view.<%= plural_table_name %>.index_title')
    @<%= plural_table_name %> = <%= orm_class.all class_name %>.page(params[:page])
  end

  # GET <%= route_url %>/1
  def show
    @title = t('view.<%= plural_table_name %>.show_title')
  end

  # GET <%= route_url %>/new
  def new
    @title = t('view.<%= plural_table_name %>.new_title')
    @<%= singular_table_name %> = <%= orm_class.build(class_name) %>
  end

  # GET <%= route_url %>/1/edit
  def edit
    @title = t('view.<%= plural_table_name %>.edit_title')
  end

  # POST <%= route_url %>
  def create
    @title = t('view.<%= plural_table_name %>.new_title')
    @<%= singular_table_name %> = <%= orm_class.build(class_name, "#{singular_table_name}_params") %>

    respond_to do |format|
      if @<%= orm_instance.save %>
        format.html { redirect_to @<%= singular_table_name %>, notice: t('view.<%= plural_table_name %>.correctly_created') }
      else
        format.html { render action: 'new' }
      end
    end
  end

  # PUT <%= route_url %>/1
  def update
    @title = t('view.<%= plural_table_name %>.edit_title')

    respond_to do |format|
      if @<%= orm_instance.update("#{singular_table_name}_params") %>
        format.html { redirect_to @<%= singular_table_name %>, notice: t('view.<%= plural_table_name %>.correctly_updated') }
      else
        format.html { render action: 'edit' }
      end
    end
  rescue ActiveRecord::StaleObjectError
    redirect_to edit_<%= singular_table_name %>_url(@<%= singular_table_name %>), alert: t('view.<%= plural_table_name %>.stale_object_error')
  end

  # DELETE <%= route_url %>/1
  def destroy
    @<%= orm_instance.destroy %>
    redirect_to <%= index_helper %>_url, notice: t('view.<%= plural_table_name %>.correctly_destroyed')
  end

  private

    def set_<%= singular_table_name %>
      @<%= singular_table_name %> = <%= orm_class.find(class_name, "params[:id]") %>
    end

    def <%= singular_table_name %>_params
      params.require(:<%= singular_table_name %>).permit(<%= attributes.map { |a| ":#{a.name}" }.join(', ') %>)
    end
end
<% end -%>
