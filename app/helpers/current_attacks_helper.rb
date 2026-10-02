module CurrentAttacksHelper
  def intensity_button_class(intensity)
    case intensity
    when 1..3 then "btn-success"
    when 4..6 then "btn-warning"
    else "btn-error"
    end
  end
end
