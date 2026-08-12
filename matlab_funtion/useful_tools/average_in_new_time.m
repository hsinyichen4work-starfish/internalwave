function variable_avg = average_in_new_time(old_time,variable,new_time)

mid_time = midpoints(new_time); mid_time = [new_time(1) mid_time new_time(end)];

variable_avg = NaN(1,length(mid_time)-1);
for t = 2 : length(mid_time)
    dum = old_time >= mid_time(t-1) & old_time <= mid_time(t);
    variable_avg(t-1) = mean(variable(dum),"omitmissing");
end