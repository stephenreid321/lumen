Lumen::App.controllers do
                        
  get '/groups/:slug' do
    @group = Group.find_by(slug: params[:slug])
    membership_required!        
    @conversations = @group.conversations
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
      @conversation_posts = @group.conversation_posts.or(q)
      @conversations = @conversations.where(:id.in => @conversation_posts.only(:conversation_id).map(&:conversation_id))
    end                         
    @conversations = @conversations.per_page(10).page(params[:page])        
    erb :'groups/group'
  end  
      
  get '/groups/:slug/leave' do
    @group = Group.find_by(slug: params[:slug])
    membership_required!
    @group.memberships.find_by(:account => current_account).destroy
    redirect "/groups/#{@group.slug}"
  end  
  
  get '/groups/:slug/notification_level/:level' do
    @group = Group.find_by(slug: params[:slug])
    membership_required!
    @group.memberships.find_by(account: current_account).update_attribute(:notification_level, params[:level]) if Membership.notification_levels.include? params[:level]
    flash[:notice] = 'Notification options updated!'
    redirect "/groups/#{@group.slug}"
  end   
        
end