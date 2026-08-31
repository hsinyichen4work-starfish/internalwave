clear; clc;
addpath(genpath('/home/hsinyi/Documents/CODE/matlab_funtion'));
%%
theta_s = 6; theta_b = 3; hc = 250; N =128;
theta_s2 = 6; theta_b2 = 0.75; hc2 = 10; N2 =128;

cd('/home/hsinyi/figure/20260821_debug_fix')
figure; clf; hold on
clear ax
ti = tiledlayout(2,4); 
ti.Padding = "compact"; ti.TileSpacing = "tight";

ax(1) = nexttile; hold on
zr = zlevs3(10,0, theta_s, theta_b, hc, N, 'r', 'new2008');
plot(zr,"Marker","o")
zr2 = zlevs3(10,0, theta_s2, theta_b2, hc2, N2, 'r', 'new2008');
plot(zr2,"Marker","o")
title(append("max dx = ",num2str(max(diff(zr)))," & ",num2str(max(diff(zr2)))))

ax(2) = nexttile; hold on
zr = zlevs3(100,0, theta_s, theta_b, hc, N, 'r', 'new2008');
plot(zr,"Marker","o")
zr2 = zlevs3(100,0, theta_s2, theta_b2, hc2, N2, 'r', 'new2008');
plot(zr2,"Marker","o")
title(append("max dx = ",num2str(max(diff(zr)))," & ",num2str(max(diff(zr2)))))

ax(3) = nexttile; hold on
zr = zlevs3(1000,0, theta_s, theta_b, hc, N, 'r', 'new2008');
plot(zr,"Marker","o")
zr2 = zlevs3(1000,0, theta_s2, theta_b2, hc2, N2, 'r', 'new2008');
plot(zr2,"Marker","o")
title(append("max dx = ",num2str(max(diff(zr)))," & ",num2str(max(diff(zr2)))))

ax(4) = nexttile; hold on
zr = zlevs3(4500,0, theta_s, theta_b, hc, N, 'r', 'new2008');
plot(zr,"Marker","o")
zr2 = zlevs3(4500,0, theta_s2, theta_b2, hc2, N2, 'r', 'new2008');
plot(zr2,"Marker","o")
title(append("max dx = ",num2str(max(diff(zr)))," & ",num2str(max(diff(zr2)))))

ax(5) = nexttile; hold on
zr = zlevs3(10,0, theta_s, theta_b, hc, N, 'r', 'new2008');
plot(diff(zr),midpoints(zr),"Marker","o")
zr2 = zlevs3(10,0, theta_s2, theta_b2, hc2, N2, 'r', 'new2008');
plot(diff(zr2),midpoints(zr2),"Marker","o")
title(append("max dx = ",num2str(max(diff(zr)))," & ",num2str(max(diff(zr2)))))

ax(6) = nexttile; hold on
zr = zlevs3(100,0, theta_s, theta_b, hc, N, 'r', 'new2008');
plot(diff(zr),midpoints(zr),"Marker","o")
zr2 = zlevs3(100,0, theta_s2, theta_b2, hc2, N2, 'r', 'new2008');
plot(diff(zr2),midpoints(zr2),"Marker","o")
title(append("max dx = ",num2str(max(diff(zr)))," & ",num2str(max(diff(zr2)))))

ax(7) = nexttile; hold on
zr = zlevs3(1000,0, theta_s, theta_b, hc, N, 'r', 'new2008');
plot(diff(zr),midpoints(zr),"Marker","o")
zr2 = zlevs3(1000,0, theta_s2, theta_b2, hc2, N2, 'r', 'new2008');
plot(diff(zr2),midpoints(zr2),"Marker","o")
title(append("max dx = ",num2str(max(diff(zr)))," & ",num2str(max(diff(zr2)))))

ax(8) = nexttile; hold on
zr = zlevs3(4500,0, theta_s, theta_b, hc, N, 'r', 'new2008');
plot(diff(zr),midpoints(zr),"Marker","o")
zr2 = zlevs3(4500,0, theta_s2, theta_b2, hc2, N2, 'r', 'new2008');
plot(diff(zr2),midpoints(zr2),"Marker","o")
title(append("max dx = ",num2str(max(diff(zr)))," & ",num2str(max(diff(zr2)))))
saveas(gcf,"zr_test.jpg")

