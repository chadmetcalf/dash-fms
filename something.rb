def totals
  res_count_sum = source_row_sum(:reservation_count)
  total_lead_sum = source_row_sum(:total_leads)

  [ total_lead_sum,
    source_row_sum(:inquiry_count),
    res_count_sum,
    source_row_sum(:move_in_count),
    source_row_sum(:cancelled_count),
    total_move_in_rate(res_count_sum, total_lead_sum)
  ]
end

def total_move_in_rate(res_count_sum, total_lead_sum)
  # total move-ins divided by total leads
  (res_count_sum.to_f / total_lead_sum.to_f) * 100.0).round(2)
end

def source_row_sum(sym)
  source_rows.sum{|sr| sr.send(sym)}
end
