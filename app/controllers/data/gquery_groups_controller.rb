class Data::GqueryGroupsController < Data::BaseController
  def index
    @gquery_groups = GqueryGroup.all
  end
  
  def show
    @gquery_group = GqueryGroup.find_by_group_key(params[:id])
    redirect_to data_gqueries_path(:group_ids => @gquery_group.id)
  end
end