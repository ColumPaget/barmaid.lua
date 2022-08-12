-- functions related to lookups of date and time

function LookupTimes()
  display_values.time=time.format("%H:%M:%S")
  display_values.date=time.format("%Y/%m/%d")
  display_values.day_name=time.format("%a")
  display_values.month_name=time.format("%b")
  display_values.hour=time.format("%H")
  display_values.minutes=time.format("%M")
  display_values.seconds=time.format("%S")
  display_values.year=time.format("%Y")
  display_values.month=time.format("%m")
  display_values.day=time.format("%d")
end




