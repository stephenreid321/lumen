require 'active_support/core_ext/integer/inflections'

Time::DATE_FORMATS.merge!(
  :default => lambda { |time| time.to_s(:date) + ', ' + time.to_s(:time) },
  :date => lambda { |time| time.to_date.to_s },
  :no_year => lambda { |time| time.to_date.to_s(:no_year) + ', ' + time.to_s(:time) },
  :time => lambda { |time| time.strftime("#{(t = time.hour%12) == 0 ? 12 : t}:%M#{time.strftime('%p').downcase}") },
  :no_double_zeros => lambda { |time| time.strftime("#{(t = time.hour%12) == 0 ? 12 : t}#{time.strftime(':%M') unless time.strftime(':%M') == ':00'}#{time.strftime('%p').downcase}") }
)

Date::DATE_FORMATS.merge!(
  :default => lambda { |date| date.strftime("%a #{date.day.ordinalize} %b %Y") },
  :no_year => lambda { |date| date.strftime("%a %-d %B") }
)