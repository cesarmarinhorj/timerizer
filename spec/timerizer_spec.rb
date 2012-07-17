require_relative '../lib/timerizer'

describe RelativeTime do
  context "given an existing time" do
    before :all do
      @time = Time.new(2000, 1, 1, 3, 45, 00)
    end

    it "calculates a new time before itself" do
      5.minutes.before(@time).should == Time.new(2000, 1, 1, 3, 40, 00)
      5.months.before(@time).should == Time.new(1999, 8, 1, 3, 45, 00)
    end

    it "calculates a new time after itself" do
      5.minutes.after(@time).should == Time.new(2000, 1, 1, 3, 50, 00)
      5.months.after(@time).should == Time.new(2000, 6, 1, 3, 45, 00)
    end
  end

  context "given an odd time case" do
    it "properly calculates the time before it" do
      end_of_march = Time.new(2000, 3, 31, 3, 45, 00)
      1.month.before(end_of_march).should == Time.new(2000, 2, 29, 3, 45, 00)
    end

    it "properly calculates the time after it" do
      end_of_january = Time.new(2000, 1, 31, 3, 45, 00)
      1.month.after(end_of_january).should == Time.new(2000, 2, 29, 3, 45, 00)
    end
  end

  it "can average from second units to month units" do
    five_weeks = {
      :seconds => 3024000,
      :average => {:seconds => 394254, :months => 1}
    }

    5.weeks.get(:seconds).should == five_weeks[:seconds]

    average = 5.weeks.average!
    average.get(:seconds).should == five_weeks[:average][:seconds]
    average.get(:months).should == five_weeks[:average][:months]
  end

  it "can unaverage from month units to second units" do
    two_months = {
      :months => 2,
      :unaverage => {:seconds => 5259492, :months => 0}
    }

    2.months.get(:months).should == two_months[:months]

    unaverage = 2.months.unaverage!

    unaverage.get(:seconds).should == two_months[:unaverage][:seconds]
    unaverage.get(:months).should == two_months[:unaverage][:months]
  end
end

describe Time do
  it "can be added or subtracted to RelativeTime" do
    time = Time.new(2000, 1, 1, 3, 45, 00)
    (time + 5.minutes).should == Time.new(2000, 1, 1, 3, 50, 00)
    (time - 5.minutes).should == Time.new(2000, 1, 1, 3, 40, 00)
  end

  it "can be converted to a Date object" do
    time = Time.new(2000, 1, 1, 11, 59, 00)
    time.to_date.should == Date.new(2000, 1, 1)
  end
end

describe Date do
  it "can be converted to a Time object" do
    date = Date.new(2000, 1, 1)
    date.to_time.should == Time.new(2000, 1, 1)
  end

  it "returns the number of days in a month" do
    Date.new(2000, 1).days_in_month.should == 31
    Date.new(2000, 2).days_in_month.should == 29
    Date.new(2001, 2).days_in_month.should == 28
  end
end

describe Fixnum do
  it "makes RelativeTime objects" do
    1.minute.get(:seconds).should == 60
    3.hours.get(:seconds).should == 10800
    5.days.get(:seconds).should == 432000
    4.years.get(:months).should == 48

    relative_time = 1.second 2.minutes 3.hours 4.days 5.weeks 6.months 7.years
    relative_time.get(:seconds).should == 3380521
    relative_time.get(:months).should == 90
  end
end
