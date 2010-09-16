class UsersController < ApplicationController
  # GET /users
  # GET /users.xml
  def index
    @title = t :'view.users.index_title'
    @users = User.paginate(
      :page => params[:page],
      :per_page => APP_LINES_PER_PAGE,
      :order => "#{User.table_name}.username ASC"
    )

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @users }
    end
  end

  # GET /users/1
  # GET /users/1.xml
  def show
    @title = t :'view.users.show_title'
    @user = User.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @user }
    end
  end

  # GET /users/new
  # GET /users/new.xml
  def new
    @title = t :'view.users.new_title'
    @user = User.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @user }
    end
  end

  # GET /users/1/edit
  def edit
    @title = t :'view.users.edit_title'
    @user = User.find(params[:id])
  end

  # POST /users
  # POST /users.xml
  def create
    @title = t :'view.users.new_title'
    @user = User.new(params[:user])

    respond_to do |format|
      if @user.save
        format.html { redirect_to(users_url, :notice => t(:'view.users.correctly_created')) }
        format.xml  { render :xml => @user, :status => :created, :location => users_url }
      else
        format.html { render :action => :new }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /users/1
  # PUT /users/1.xml
  def update
    @title = t :'view.users.edit_title'
    @user = User.find(params[:id])

    respond_to do |format|
      if @user.update_attributes(params[:user])
        format.html { redirect_to(users_url, :notice => t(:'view.users.correctly_updated')) }
        format.xml  { head :ok }
      else
        format.html { render :action => :edit }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash[:alert] = t :'view.users.stale_object_error'
    redirect_to edit_user_url(@user)
  end

  # DELETE /users/1
  # DELETE /users/1.xml
  def destroy
    @user = User.find(params[:id])
    @user.destroy

    respond_to do |format|
      format.html { redirect_to(users_url) }
      format.xml  { head :ok }
    end
  end
end