module MedicationsHelper
  EFFECTIVENESS_EMOJI = { "helped" => "👍", "no_effect" => "➡️", "made_worse" => "👎" }.freeze
  KIND_ICONS = { "abortive" => "bolt", "oxygen" => "cloud", "preventive" => "shield-check", "other" => "beaker" }.freeze
  SUGGESTED_MEDICATIONS = { "Oxygen" => "oxygen", "Sumatriptan" => "abortive", "Zolmitriptan" => "abortive" }.freeze

  # One prefilled dose per picker button: the medications taken for attacks
  # most recently first, then preventives (taken daily, they would otherwise
  # crowd out oxygen). Someone without medications yet gets the usual
  # cluster headache abortives to start from.
  def medication_picker_options(user)
    medications = user.medications.active.by_recent_use.to_a

    if medications.any?
      medications.partition { |medication| !medication.preventive? }.flatten.map do |medication|
        MedicationDose.new(medication: medication, amount: medication.default_dose, unit: medication.unit)
      end
    else
      SUGGESTED_MEDICATIONS.map do |name, kind|
        medication = Medication.new(name: name, kind: kind, unit: (Medication::OXYGEN_UNIT if kind == "oxygen"))
        MedicationDose.new(medication: medication, medication_name: name, medication_kind: kind, unit: medication.unit)
      end
    end
  end

  def medication_picker_template_id(dose)
    if dose.medication.persisted?
      dom_id(dose.medication, :dose_template)
    else
      "suggested_#{dose.medication.name.parameterize}_dose_template"
    end
  end

  # A GitHub-label-like pill in the medication's own color, so a name reads
  # as a thing that was picked, not free text.
  def medication_tag(medication, label = medication.name, size: :sm, **options)
    color = medication.display_color

    tag.span label, **options.except(:class),
      class: [ "medication-tag inline-block rounded-full font-semibold leading-tight whitespace-normal",
        size == :lg ? "px-3 py-1.5 text-sm" : "px-2 py-0.5 text-xs", options[:class] ],
      style: "background-color: #{color}; color: #{readable_text_color(color)};"
  end

  def dose_tag(dose, **options)
    medication_tag dose.medication, [ dose.medication.name, dose.amount_label, dose.duration_label ].compact.join(" · "), **options
  end

  def effectiveness_emoji(effectiveness)
    EFFECTIVENESS_EMOJI[effectiveness.to_s]
  end

  def effectiveness_badge(dose)
    if dose.effectiveness
      tag.span effectiveness_emoji(dose.effectiveness), title: t("medication_doses.effectiveness.#{dose.effectiveness}"),
        aria: { label: t("medication_doses.effectiveness.#{dose.effectiveness}") }
    end
  end

  def medication_kind_icon(medication, **options)
    heroicon KIND_ICONS.fetch(medication.kind, "beaker"), variant: "mini", **options
  end

  def medication_schedule_label(medication)
    [ t("medications.frequencies.#{medication.frequency}"), medication.schedule_note ].compact_blank.join(" · ")
  end

  def medication_status(medication)
    if medication.daily?
      t("medications.status.taken_today", taken: medication.doses_taken_today, expected: medication.doses_per_day)
    elsif next_due = medication.next_due_at
      days = (next_due.to_date - Date.current).to_i

      if days.negative?
        t("medications.status.overdue", count: -days)
      else
        t("medications.status.due_in", count: days)
      end
    end
  end

  RELIEF_CHOICES = [ 5, 10, 15, 20, 30, 45, 60 ].freeze

  # Quick answers for "how long until relief?", led by the time between
  # the dose and the end of the attack when that is known.
  def medication_relief_choices(dose)
    [ dose.minutes_until_attack_ended, *RELIEF_CHOICES ].compact.uniq
  end

  def medication_adherence_chart_labels
    {
      title: t("medications.insights.adherence_chart.title"),
      attacks: t("medications.insights.adherence_chart.attacks"),
      adherence: t("medications.insights.adherence_chart.adherence"),
      week: t("medications.insights.adherence_chart.week")
    }
  end

  def dose_time(time)
    l(time, format: :medication_dose)
  end

  def readable_text_color(hex)
    red, green, blue = hex.delete_prefix("#").scan(/../).map { |channel| channel.to_i(16) }
    luminance = (0.299 * red + 0.587 * green + 0.114 * blue) / 255

    luminance > 0.6 ? "#1f2937" : "#ffffff"
  end
end
