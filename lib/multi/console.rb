# to call Multi::Tenant.init
def reload!(print=true)
  puts "Reloading..." if print
  # This triggers the to_prepare callbacks
  ActionDispatch::Callbacks.new(Proc.new {}).call({})
  # Manually init Multi again once classes are reloaded
  Multi::Tenant.init
  true
end
