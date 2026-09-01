
[z_prof] = get_ncom_z(pgrid,-zset);
scatter((length(z_prof):-1:1)./length(z_prof),z_prof,[],1 : length(z_prof),"filled")

zr = zlevs3(zset,0, theta_s, theta_b, hc, N, 'r', 'new2008');
plot((1:length(zr))./length(zr),zr,"Marker","o","LineWidth",1,"Color",[0.0660    0.4430    0.7450])
zr2 = zlevs3(zset,0, theta_s2, theta_b2, hc2, N2, 'r', 'new2008');
plot((1:length(zr2))./length(zr2),zr2,"Marker","o","LineWidth",1,"Color",[0.8660    0.3290         0])

title(append("max dz = ",num2str(max(diff(zr)))," & "), ...
    append(num2str(max(diff(zr2)))," & ",num2str(max(-diff(z_prof)))))

% --- Local Function ---
function [z_prof] = get_ncom_z(pgrid,zset)
    [~,linear_idx] = min(abs(pgrid.h - (zset)),[],"all"); 
    [row, col] = ind2sub(size(pgrid.h), linear_idx); 
    z_prof = squeeze(pgrid.zw3(row, col,:));
end