module ChartsHelper
  def pressure_chart_labels
    {
      byPressureTitle: t("barometric_pressure.charts.by_pressure.title"),
      pressureAxis: t("barometric_pressure.charts.by_pressure.x_axis"),
      frequency: t("barometric_pressure.charts.by_pressure.frequency"),
      averageIntensity: t("barometric_pressure.charts.by_pressure.avg_intensity"),
      changeTitle: t("barometric_pressure.charts.change.title"),
      changeAxis: t("barometric_pressure.charts.change.y_axis"),
      changeDataset: t("barometric_pressure.charts.change.dataset"),
      dateAxis: t("barometric_pressure.charts.change.x_axis"),
      changeTooltip: t("barometric_pressure.charts.change.tooltip.change", value: "%{value}"),
      pressureTooltip: t("barometric_pressure.charts.change.tooltip.pressure", value: "%{value}"),
      hoursTooltip: t("barometric_pressure.charts.change.tooltip.hours", value: "%{value}"),
      intensityTooltip: t("barometric_pressure.charts.change.tooltip.intensity", value: "%{value}")
    }
  end
end
