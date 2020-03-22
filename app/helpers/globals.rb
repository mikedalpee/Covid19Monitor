module Globals

  def self.globals
    @@globals||= Hash.new {|h,k| h[k] = nil}
  end

  def self.m
    @@m ||= Mutex.new
  end

  def self.get(global_id)
    m.synchronize {
      globals[global_id]
    }
  end

  def self.set(global_id,value)
    m.synchronize {
      globals[global_id] = value
    }
  end

end