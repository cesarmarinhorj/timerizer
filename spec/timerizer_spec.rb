require "spec_helper"

RSpec.describe RelativeTime do
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

    it "properly handles large periods of time" do
      65.months.before(@time).should == Time.new(1994, 8, 1, 3, 45, 00)
      65.months.after(@time).should == Time.new(2005, 6, 1, 3, 45, 00)
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

  context "#to_wall" do
    it "calculates an equivalent WallClock time" do
      (5.hours 30.minutes).to_wall.should == WallClock.new(5, 30)
    end

    it "raises an error for times beyond 24 hours" do
      expect do
        1.day.to_wall
      end.to raise_error WallClock::TimeOutOfBoundsError

      expect do
        217.hours.to_wall
      end.to raise_error WallClock::TimeOutOfBoundsError

      expect do
        (1.month 3.seconds).to_wall
      end.to raise_error WallClock::TimeOutOfBoundsError
    end
  end

  context "#to_s" do
    it "converts all units into a string" do
      (1.hour 3.minutes 4.seconds).to_s.should ==
        "1 hour, 3 minutes, 4 seconds"
      (1.year 3.months 4.days).to_s(:long).should ==
        "1 year, 3 months, 4 days"
    end

    it "converts units into a micro syntax" do
      (1.hour 3.minutes 4.seconds).to_s(:micro).should ==
        "1h"
      (1.year 3.months 4.days).to_s(:micro).should ==
        "1y"
    end

    it "converts units into a medium syntax" do
      (1.hour 3.minutes 4.seconds).to_s(:short).should ==
        "1hr 3min"
      (1.year 3.months 4.days).to_s(:short).should ==
        "1yr 3mn"
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

  it "can compare two RelativeTimes" do
    1.minute.should == 1.minute
    1.minute.should_not == 1.hour
  end
end

describe WallClock do
  it "can be created" do
    WallClock.new(12, 30, :pm)
    WallClock.new(23, 30)
  end

  it "can be created from a string" do
    WallClock.from_string("9:00 PM").should == WallClock.new(9, 00, :pm)
    WallClock.from_string("13:00").should == WallClock.new(13, 00)
    WallClock.from_string("12:00 PM").should == WallClock.new(12, 00, :pm)
    WallClock.from_string("11:00:01 PM").should == WallClock.new(11, 00, 01, :pm)
    WallClock.from_string("23:34:45").should == WallClock.new(23, 34, 45)
  end

  it "can apply a time on a day" do
    date = Date.new(2000, 1, 1)
    WallClock.new(9, 00, :pm).on(date).should == Time.new(2000, 1, 1, 21)
  end

  it "can be initialized from a hash of values" do
    date = Date.new(2000, 1, 1)
    WallClock.new(:second => 30*60).on(date).should == Time.new(2000, 1, 1, 0, 30)
  end

  it "can be converted to an from an integer" do
    time = WallClock.new(21, 00)
    WallClock.new(time.to_i).should == WallClock.new(9, 00, :pm)
  end

  it "can return its components" do
    time = WallClock.new(5, 35, 45, :pm)
    time.hour.should == 17
    time.hour(:twenty_four_hour).should == 17
    time.hour(:twelve_hour).should == 5
    time.minute.should == 35
    time.second.should == 45
    time.meridiem.should == :pm

    time.in_seconds.should == (17*3600) + (35*60) + 45
    time.in_minutes.should == (17*60) + 35
    time.in_hours.should == 17

    expect do
      time.hour(:thirteen_hour)
    end.to raise_error ArgumentError
  end

  it "raises an error for invalid wallclock times" do
    expect do
      WallClock.new(13, 00, :pm)
    end.to raise_error(WallClock::TimeOutOfBoundsError)

    expect do
      WallClock.new(24, 00, 00)
    end.to raise_error(WallClock::TimeOutOfBoundsError)

    expect do
      WallClock.new(0, 60)
    end.to raise_error(WallClock::TimeOutOfBoundsError)
  end

  it "can be converted to RelativeTime" do
    WallClock.new(5, 30, 27, :pm).to_relative.should ==
      (17.hours 30.minutes 27.seconds)
  end

  context "#to_s" do
    before do
      @time = WallClock.new(5, 30, 27, :pm)
    end

    it "can be converted to a 12-hour time string" do
      @time.to_s.should == "5:30:27 PM"
      @time.to_s(:twelve_hour).should == "5:30:27 PM"
      @time.to_s(:twelve_hour, :use_seconds => false).should == "5:30 PM"
      @time.to_s(:twelve_hour, :include_meridiem => false).should == "5:30:27"
      @time.to_s(
        :twelve_hour,
        :include_meridiem => false,
        :use_seconds => false
      ).should == "5:30"
    end

    it "can be converted to a 24-hour time string" do
      @time.to_s(:twenty_four_hour).should == "17:30:27"
      @time.to_s(:twenty_four_hour, :use_seconds => false).should == "17:30"
    end

    it "zero-pads units" do
      time = WallClock.new(0, 00, 00)
      time.to_s(:twelve_hour).should == "12:00:00 PM"
      time.to_s(:twenty_four_hour).should == "0:00:00"

      time.to_s(:twelve_hour, :use_seconds => false).should == "12:00 PM"
      time.to_s(:twenty_four_hour, :use_seconds => false).should == "0:00"
    end
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

  it "calculates the time between two Times" do
    time = 1.minute.ago
    Time.until(1.minute.from_now).in_seconds.should be_within(1.0).of(60)
    Time.since(1.hour.ago).in_seconds.should be_within(1.0).of(3600)

    Time.between(1.minute.ago, 2.minutes.ago).in_seconds.should be_within(1.0).of(60)
    Time.between(Date.yesterday, Date.tomorrow).in_seconds.should be_within(1.0).of(2.days.in_seconds)

    lambda do
      Time.until(1.minute.ago)
    end.should raise_error(Time::TimeIsInThePastError)

    lambda do
      Time.since(Date.tomorrow)
    end.should raise_error(Time::TimeIsInTheFutureError)
  end

  it "can be converted to a WallClock time" do
    time = Time.new(2000, 1, 1, 17, 58, 04)
    time.to_wall.should == WallClock.new(5, 58, 04, :pm)
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

  it "returns the date yesterday and tomorrow" do
    yesterday = 1.day.ago.to_date
    tomorrow = 1.day.from_now.to_date

    Date.yesterday.should == yesterday
    Date.tomorrow.should == tomorrow
  end

  it "returns the time on a given date" do
     date = Date.new(2000, 1, 1)
     time = WallClock.new(5, 00, :pm)
     date.at(time).should == Time.new(2000, 1, 1, 17)
  end
end

describe Integer do
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
