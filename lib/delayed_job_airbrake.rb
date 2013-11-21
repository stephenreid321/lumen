if defined? Delayed::Job and defined? Airbrake 
  module Delayed
    class Worker
      alias_method :original_handle_failed_job, :handle_failed_job

      protected
      def handle_failed_job(job, error)
        Airbrake.notify(error)
        original_handle_failed_job(job,error)
      end
    end
  end
end
