class UserSessionsController < ApplicationController
  layout 'pages'

  before_filter :require_no_user, :only => :new

  def index
    @user_session = UserSession.new
    render :action=>"new"
  end

  def new
    @user_session = UserSession.new
  end

  def create
    @user_session = UserSession.new(params[:user_session])
    if @user_session.save
      flash[:notice] = I18n.t("flash.login")
      redirect_to data_root_path(:blueprint_id => 'latest', :region_code => 'nl')
    else
      render :action => 'new'
    end
  end

  def destroy
    @user_session = UserSession.find
    @user_session.destroy if @user_session

    respond_to do |format|
      flash[:notice] = I18n.t("flash.logout")
      format.html { redirect_to(root_url) }
      format.xml  { head :ok }
    end
  end
end
