class Delayed::Job
  
  after_save :notify_on_error
  def notify_on_error
    if self.last_error
      begin
        raise (r = "Delayed::Job error")
      rescue => e
        puts r
        Airbrake.notify(e, :parameters => {:last_error => self.last_error})
      end      
    end
  end
  
end