module HeadacheLogsHelper
  # Interpolates from green (low) through yellow to red (high) on the 1-10 intensity scale.
  def intensity_color(intensity)
    return "hsl(142, 71%, 45%)" if intensity <= 3

    if intensity <= 6
      ratio = (intensity - 3) / 3.0
      "hsl(#{(142 - ratio * 97).round}, #{(71 + ratio * 22).round}%, #{(45 + ratio * 2).round}%)"
    else
      ratio = (intensity - 6) / 4.0
      "hsl(#{(45 * (1 - ratio)).round}, #{(93 - ratio * 9).round}%, #{(47 + ratio * 13).round}%)"
    end
  end
end
