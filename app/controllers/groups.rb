Lumen::App.controllers do
  
  get '/groups/new' do
    sign_in_required!
    @group = Group.new
    erb :'groups/build'
  end
  
  post '/groups/new' do
    sign_in_required!
    @group = Group.new(params[:group])    
    if @group.save  
      flash[:notice] = "<strong>Great!</strong> The group was created successfully."
      @group.memberships.create! :account => current_account, :role => 'admin'
      redirect "/groups/#{@group.slug}"
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the group from being saved."
      erb :'groups/build'
    end    
  end
  
  get '/groups/type/:slug' do
    sign_in_required!
    @group_type = GroupType.find_by(slug: params[:slug])
    erb :'/groups/group_type'
  end  
                          
  get '/groups/:slug' do
    @group = Group.find_by(slug: params[:slug])
    membership_required! unless @group.open?
    @membership = @group.memberships.find_by(account: current_account)
    @conversations = @group.conversations.where(:hidden.ne => true)
    @q = params[:q] if params[:q]        
    if @q
      q = []
      ConversationPost.fields.each { |fieldstring, fieldobj|
        if fieldobj.type == String and !fieldstring.starts_with?('_')          
          q << {fieldstring.to_sym => /#{@q}/i }
        elsif fieldstring.ends_with?('_id') && (assoc_name = ConversationPost.fields[fieldstring].metadata.try(:class_name))          
          q << {"#{assoc_name.underscore}_id".to_sym.in => assoc_name.constantize.where(assoc_name.constantize.send(:lookup) => /#{@q}/i).only(:_id).map(&:_id) }
        end
      }   
      @conversation_posts = @group.conversation_posts.where(:hidden.ne => true).or(q)
      @conversations = @conversations.where(:id.in => @conversation_posts.only(:conversation_id).map(&:conversation_id))
    end                         
    @conversations = @conversations.order_by(:updated_at.desc).per_page(10).page(params[:page])        
    erb :'groups/group'
  end  
      
  get '/groups/:slug/leave' do
    @group = Group.find_by(slug: params[:slug])
    membership_required!
    @group.memberships.find_by(:account => current_account).destroy
    redirect "/groups/#{@group.slug}"
  end  
  
  get '/groups/:slug/notification_level' do
    @group = Group.find_by(slug: params[:slug])
    membership_required!
    @group.memberships.find_by(account: current_account).update_attribute(:notification_level, params[:level]) if Membership.notification_levels.include? params[:level]
    flash[:notice] = 'Notification options updated!'
    redirect "/groups/#{@group.slug}"
  end   
          
end