module LocomotiveEditor
  module Logger

    def self.info(msg)
      _base(:info, msg)
    end

    def self.error(msg)
      _base(:error, msg)
    end

    def self.warn(msg)
      _base(:error, msg)
    end

    def self._base(level, msg)
      puts "[LocomotiveEditor][#{level.to_s.upcase}] #{msg}"
    end

  end
end