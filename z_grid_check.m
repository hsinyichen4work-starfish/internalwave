clear; clc;
addpath(genpath('/home/hsinyi/Documents/CODE/matlab_funtion'));

%%
parent_grid = '/home/mbui/ModelOutput/NCOM/grid/ohgrd_2.nc';
pgrid = read_nc_fun(parent_grid);
child_grid = '/home/hsinyi/roms_data/grid/roms_grd_900m.nc';
cgrid = read_nc_fun(child_grid);
%%
min(cgrid.h,[],"all")
%%
theta_s = 6; theta_b = 3; hc = 250; N =128;
theta_s2 = 6; theta_b2 = 0.75; hc2 = 10; N2 =128;
theta_s3 = 6; theta_b3 = 6; hc3 = 250; N3 =128;

cd('/home/hsinyi/figure/20260821_debug_fix')
figure; clf; hold on
clear ax; colormap("jet")
ti = tiledlayout(2,4); 
ti.Padding = "compact"; %ti.TileSpacing = "tight";

ax(1) = nexttile; hold on
zset = 10; z_ratio_plt

ax(2) = nexttile; hold on
zset = 100; z_ratio_plt

ax(3) = nexttile; hold on
zset = 1000; z_ratio_plt

ax(4) = nexttile; hold on
zset = 4500; z_ratio_plt
colorbar

ax(5) = nexttile; hold on
zset = 10; z_diff_plt

ax(6) = nexttile; hold on
zset = 100; z_diff_plt

ax(7) = nexttile; hold on
zset = 1000; z_diff_plt

ax(8) = nexttile; hold on
zset = 4500; z_diff_plt
colorbar
saveas(gcf,"zr_test2.jpg")

%%
[~,linear_idx] = min(abs(pgrid.h - (-10)),[],"all"); pgrid.h(linear_idx)
[row, col] = ind2sub(size(pgrid.h), linear_idx); pgrid.h(row, col)
z_prof = squeeze(pgrid.zw3(row, col,:)); length(find(~isnan(z_prof)))

[~,linear_idx] = min(abs(pgrid.h - (-100)),[],"all"); 
[row, col] = ind2sub(size(pgrid.h), linear_idx); 
z_prof = squeeze(pgrid.zw3(row, col,:)); length(find(~isnan(z_prof)))

[~,linear_idx] = min(abs(pgrid.h - (-1000)),[],"all"); 
[row, col] = ind2sub(size(pgrid.h), linear_idx); 
z_prof = squeeze(pgrid.zw3(row, col,:)); length(find(~isnan(z_prof)))

%%
theta_s = 6; theta_b = 3; hc = 250; N =128;
theta_s3 = 6; theta_b3 = 6; hc3 = 250; N3 =128;

dep = [10 : 10 : 5000]; interest_dep = [-1 : -2 : -1500];
dz_mat1 = NaN(length(interest_dep),length(dep));
dz_mat13 = NaN(length(interest_dep),length(dep));
for k = 1 : length(dep)
    zr = zlevs3(dep(k),0, theta_s, theta_b, hc, N, 'r', 'new2008');
    dz_mat1(:,k) = interp1(midpoints(zr)',diff(zr),interest_dep);
    zr = zlevs3(dep(k),0, theta_s3, theta_b3, hc3, N3, 'r', 'new2008');
    dz_mat3(:,k) = interp1(midpoints(zr)',diff(zr),interest_dep);
end
%%
figure; clf; hold on
clear ax; 
ti = tiledlayout(2,1); 
ti.Padding = "compact"; %ti.TileSpacing = "tight";

ax(1) = nexttile; hold on
contourf(dep,interest_dep,dz_mat1,[0:1:60]); shading flat; colorbar
clim([0 65]); title("6/3/250")
ax(2) = nexttile; hold on
contourf(dep,interest_dep,dz_mat3,[0:1:60]); shading flat; colorbar
clim([0 65]); title("6/6/250")
cd('/home/hsinyi/figure/20260821_debug_fix')
saveas(gcf,"dz_intrested2.jpg")
linkaxes(ax,"xy"); ylim([-100 0]); clim(ax,[0 10]);
saveas(gcf,"dz_intrested2_2.jpg")

linkaxes(ax,"xy"); ylim([-200 0]); clim(ax,[0 15]);
saveas(gcf,"dz_intrested2_3.jpg")