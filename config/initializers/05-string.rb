# frozen_string_literal: true

class String
  def presence
    if self == ""
      nil
    else
      self
    end
  end
end
