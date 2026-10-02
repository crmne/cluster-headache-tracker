class HeadacheLog::ImportResult
  attr_reader :format, :imported, :duplicates, :invalid

  def initialize(format:)
    @format = format
    @imported = @duplicates = @invalid = 0
  end

  def record(outcome)
    case outcome
    when :imported then @imported += 1
    when :duplicate then @duplicates += 1
    when :invalid then @invalid += 1
    end
  end

  def skipped = duplicates + invalid
end
