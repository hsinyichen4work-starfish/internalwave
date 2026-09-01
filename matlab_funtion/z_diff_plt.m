
[z_prof] = get_ncom_z(pgrid,-zset);
scatter(-diff(z_prof),midpoints(z_prof),[],midpoints(1 : length(z_prof)),"filled")

zr = zlevs3(zset,0, theta_s, theta_b, hc, N, 'r', 'new2008');
plot(diff(zr),midpoints(zr),"Marker","o","Color",[0.0660    0.4430    0.7450])
zr2 = zlevs3(zset,0, theta_s2, theta_b2, hc2, N2, 'r', 'new2008');
plot(diff(zr2),midpoints(zr2),"Marker","o","Color",[0.8660    0.3290         0])

title(append("min dz = ",num2str(min(diff(zr)))," & "), ...
    append(num2str(min(diff(zr2)))," & ",num2str(min(-diff(z_prof)))))

% --- Local Function ---
function [z_prof] = get_ncom_z(pgrid,zset)
    [~,linear_idx] = min(abs(pgrid.h - (zset)),[],"all"); 
    [row, col] = ind2sub(size(pgrid.h), linear_idx); 
    z_prof = squeeze(pgrid.zw3(row, col,:));
end