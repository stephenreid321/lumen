HireFire::Resource.configure do |config|
  config.dyno(:worker) do
    HireFire::Macro::Delayed::Job.queue(:mapper => :mongoid)
  end
end