class SpeedReporter

  attr_accessor :report_every

  def initialize(unit)
    @started = Time.now
    @num_processed = 0
    @report_every = 1000
    @last_reported = 0
    @unit = unit
  end

  def processed(amount)
    @num_processed += amount

    if @num_processed > @last_reported + @report_every
      @elapsed = Time.now - @started

      puts "Processed #@num_processed: #{(@num_processed / @elapsed).round} #@unit / sec"

      @last_reported = 0
    end
  end
end