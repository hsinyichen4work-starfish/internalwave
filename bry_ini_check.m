clear; clc
addpath(genpath('/home/hsinyi/Documents/CODE/matlab_funtion/'));

%% path setting
boundary_path = '/home/hsinyi/roms_data/bry/';
figure_path = '/home/hsinyi/figure/20260821_debug_fix/';
initial_path = '/home/hsinyi/roms_data/ini/';
grid_path = '/home/hsinyi/roms_data/grid/';

bry_file = 'roms_bry_300m_2022082200.nc';
gridfile = 'roms_grd_300m.nc'
ini_file = 'roms_ini_300m.nc';

ini_test_read = read_nc_fun([initial_path,ini_file]);
grd_test_read = read_nc_fun([grid_path,gridfile]);
bry_test_read = read_nc_fun([boundary_path,bry_file]);

scoord.theta_s = ini_test_read.theta_s;
scoord.theta_b = ini_test_read.theta_b;
scoord.hc = ini_test_read.hc;
scoord.N = size(ini_test_read.u,3);
scoord.scoord = 'new2008';

ROMS_z = ROMS_zgrid(grd_test_read.h,ini_test_read.zeta,scoord,'r');
ROMS_z = permute(ROMS_z,[2 3 1]);
balance = cmocean('balance');
thermal = cmocean('thermal');

% check ssh at boundary
cd(figure_path)
figure; clf; hold on
ti = tiledlayout(4,1); ti.Padding = "compact"; ti.TileSpacing = "tight";

ax(1) = nexttile; hold on
plot(bry_test_read.zeta_east(:,1),"linewidth",1);
plot(ini_test_read.zeta(end,:),"linewidth",2,"linestyle","--");
title("east")

ax(2) = nexttile; hold on
plot(bry_test_read.zeta_west(:,1),"linewidth",1);
plot(ini_test_read.zeta(1,:),"linewidth",2,"linestyle","--");
title("west")

ax(3) = nexttile; hold on
plot(bry_test_read.zeta_north(:,1),"linewidth",1);
plot(ini_test_read.zeta(:,end),"linewidth",2,"linestyle","--");
title("north")

ax(4) = nexttile; hold on
plot(bry_test_read.zeta_south(:,1),"linewidth",1);
plot(ini_test_read.zeta(:,1),"linewidth",2,"linestyle","--");
title("south")
title(ti,"boundary / inital ssh (m) match")
saveas(gcf,"boundary_test_ssh.jpg")

% check ubar / vbar at boundary
cd(figure_path)
figure; clf; hold on
ti = tiledlayout(4,2); ti.Padding = "compact"; ti.TileSpacing = "tight";

ax(1) = nexttile; hold on
plot(bry_test_read.ubar_east(:,1),"linewidth",1);
plot(ini_test_read.ubar(end,:),"linewidth",2,"linestyle","--");
title("east")

ax(2) = nexttile(3); hold on
plot(bry_test_read.ubar_west(:,1),"linewidth",1);
plot(ini_test_read.ubar(1,:),"linewidth",2,"linestyle","--");
title("west")

ax(3) = nexttile(5); hold on
plot(bry_test_read.ubar_north(:,1),"linewidth",1);
plot(ini_test_read.ubar(:,end),"linewidth",2,"linestyle","--");
title("north")

ax(4) = nexttile(7); hold on
plot(bry_test_read.ubar_south(:,1),"linewidth",1);
plot(ini_test_read.ubar(:,1),"linewidth",2,"linestyle","--");
title("south")

ax(5) = nexttile; hold on
plot(bry_test_read.vbar_east(:,1),"linewidth",1);
plot(ini_test_read.vbar(end,:),"linewidth",2,"linestyle","--");
title("east")

ax(6) = nexttile; hold on
plot(bry_test_read.vbar_west(:,1),"linewidth",1);
plot(ini_test_read.vbar(1,:),"linewidth",2,"linestyle","--");
title("west")

ax(7) = nexttile; hold on
plot(bry_test_read.vbar_north(:,1),"linewidth",1);
plot(ini_test_read.vbar(:,end),"linewidth",2,"linestyle","--");
title("north")

ax(8) = nexttile; hold on
plot(bry_test_read.vbar_south(:,1),"linewidth",1);
plot(ini_test_read.vbar(:,1),"linewidth",2,"linestyle","--");
title("south")

title(ti,"boundary / inital ubar (left) vbar (right) (m/s) match")
saveas(gcf,"boundary_test_btvel.jpg")

% check u / v at boundary
cd(figure_path)
figure; clf; hold on
colormap(balance)
ti = tiledlayout(4,2); ti.Padding = "compact"; ti.TileSpacing = "tight";
ax(1) = nexttile; hold on
contourf(bry_test_read.u_east(:,:,1),-1.5 : 0.1 :1.5,...
     'LineStyle','none');
title("east boundary"); colorbar

ax(2) = nexttile; hold on
contourf(squeeze(ini_test_read.u(end,:,:)),...
    -1.5 : 0.1 :1.5, 'LineStyle','none');
title("east initial"); colorbar
clim(ax,[-1 1]*1.5)

ax(3) = nexttile; hold on
contourf(bry_test_read.u_west(:,:,1),-1.5 : 0.1 :1.5,...
     'LineStyle','none');
title("west boundary"); colorbar

ax(4) = nexttile; hold on
contourf(squeeze(ini_test_read.u(1,:,:)),...
    -1.5 : 0.1 :1.5, 'LineStyle','none');
title("west initial"); colorbar
clim(ax,[-1 1]*1.5)

ax(5) = nexttile; hold on
contourf(bry_test_read.u_north(:,:,1),-1.5 : 0.1 :1.5,...
     'LineStyle','none');
title("north boundary"); colorbar

ax(6) = nexttile; hold on
contourf(squeeze(ini_test_read.u(:,end,:)),...
    -1.5 : 0.1 :1.5, 'LineStyle','none');
title("north initial"); colorbar
clim(ax,[-1 1]*1.5)

ax(7) = nexttile; hold on
contourf(bry_test_read.u_south(:,:,1),-1.5 : 0.1 :1.5,...
     'LineStyle','none');
title("north boundary"); colorbar

ax(8) = nexttile; hold on
contourf(squeeze(ini_test_read.u(:,1,:)),...
    -1.5 : 0.1 :1.5, 'LineStyle','none');
title("north initial"); colorbar
clim(ax,[-1 1]*1.5)
title(ti,"boundary / inital u (m/s) match")
saveas(gcf,"boundary_test_uvel_cf.jpg")

% check u / v at boundary
cd(figure_path)
figure; clf; hold on
colormap(balance)
ti = tiledlayout(4,2); ti.Padding = "compact"; ti.TileSpacing = "tight";
ax(1) = nexttile; hold on
contourf(bry_test_read.v_east(:,:,1),-1.5 : 0.1 :1.5,...
     'LineStyle','none');
title("east boundary"); colorbar

ax(2) = nexttile; hold on
contourf(squeeze(ini_test_read.v(end,:,:)),...
    -1.5 : 0.1 :1.5, 'LineStyle','none');
title("east initial"); colorbar
clim(ax,[-1 1]*1.5)

ax(3) = nexttile; hold on
contourf(bry_test_read.v_west(:,:,1),-1.5 : 0.1 :1.5,...
     'LineStyle','none');
title("west boundary"); colorbar

ax(4) = nexttile; hold on
contourf(squeeze(ini_test_read.v(1,:,:)),...
    -1.5 : 0.1 :1.5, 'LineStyle','none');
title("west initial"); colorbar
clim(ax,[-1 1]*1.5)

ax(5) = nexttile; hold on
contourf(bry_test_read.v_north(:,:,1),-1.5 : 0.1 :1.5,...
     'LineStyle','none');
title("north boundary"); colorbar

ax(6) = nexttile; hold on
contourf(squeeze(ini_test_read.v(:,end,:)),...
    -1.5 : 0.1 :1.5, 'LineStyle','none');
title("north initial"); colorbar
clim(ax,[-1 1]*1.5)

ax(7) = nexttile; hold on
contourf(bry_test_read.v_south(:,:,1),-1.5 : 0.1 :1.5,...
     'LineStyle','none');
title("north boundary"); colorbar

ax(8) = nexttile; hold on
contourf(squeeze(ini_test_read.v(:,1,:)),...
    -1.5 : 0.1 :1.5, 'LineStyle','none');
title("north initial"); colorbar
clim(ax,[-1 1]*1.5)
title(ti,"boundary / inital v (m/s) match")
saveas(gcf,"boundary_test_vvel_cf.jpg")

% check u / v at boundary
cd(figure_path)
figure; clf; hold on
ti = tiledlayout(4,2); ti.Padding = "compact"; ti.TileSpacing = "tight";
ax(1) = nexttile; hold on
contour(bry_test_read.u_east(:,:,1),-1.5 : 0.1 :1.5,"color","k");
contour(squeeze(ini_test_read.u(end,:,:)),-1.5 : 0.1 :1.5,"linestyle","--","color","r");
title("east")

ax(2) = nexttile(3); hold on
contour(bry_test_read.u_west(:,:,1),-1.5 : 0.1 :1.5,"color","k");
contour(squeeze(ini_test_read.u(1,:,:)),-1.5 : 0.1 :1.5,"linestyle","--","color","r");
title("west")

ax(3) = nexttile(5); hold on
contour(bry_test_read.u_north(:,:,1),-1.5 : 0.1 :1.5,"color","k");
contour(squeeze(ini_test_read.u(:,end,:)),-1.5 : 0.1 :1.5,"linestyle","--","color","r");
title("north")

ax(4) = nexttile(7); hold on
contour(bry_test_read.u_south(:,:,1),-1.5 : 0.1 :1.5,"color","k");
contour(squeeze(ini_test_read.u(:,1,:)),-1.5 : 0.1 :1.5,"linestyle","--","color","r");
title("south")

ax(5) = nexttile; hold on
contour(bry_test_read.v_east(:,:,1),-1.5 : 0.1 :1.5,"color","k");
contour(squeeze(ini_test_read.v(end,:,:)),-1.5 : 0.1 :1.5,"linestyle","--","color","r");
title("east")

ax(6) = nexttile; hold on
contour(bry_test_read.v_west(:,:,1),-1.5 : 0.1 :1.5,"color","k");
contour(squeeze(ini_test_read.v(1,:,:)),-1.5 : 0.1 :1.5,"linestyle","--","color","r");
title("west")

ax(7) = nexttile; hold on
contour(bry_test_read.v_north(:,:,1),-1.5 : 0.1 :1.5,"color","k");
contour(squeeze(ini_test_read.v(:,end,:)),-1.5 : 0.1 :1.5,"linestyle","--","color","r");
title("north")

ax(8) = nexttile; hold on
contour(bry_test_read.v_south(:,:,1),-1.5 : 0.1 :1.5,"color","k");
contour(squeeze(ini_test_read.v(:,1,:)),-1.5 : 0.1 :1.5,"linestyle","--","color","r");
title("south")

title(ti,"boundary / inital u (left) v (right) (m/s) match")
saveas(gcf,"boundary_test_vel.jpg")

% % check u / v at boundary
% cd(figure_path)
% figure; clf; hold on
% colormap(balance)
% ti = tiledlayout(4,2); ti.Padding = "compact"; ti.TileSpacing = "tight";
% ax(1) = nexttile; hold on
% pcolor(bry_test_read.u_east(:,:,1)-squeeze(ini_test_read.u(end,:,:)));
% clim([-1 1]*0.1);colorbar
% title("east")

% ax(2) = nexttile(3); hold on
% pcolor(bry_test_read.u_west(:,:,1)-squeeze(ini_test_read.u(1,:,:)));
% clim([-1 1]*0.1);colorbar
% title("west")

% ax(3) = nexttile(5); hold on
% pcolor(bry_test_read.u_north(:,:,1)-squeeze(ini_test_read.u(:,end,:)));
% clim([-1 1]*0.1);colorbar
% title("north")

% ax(4) = nexttile(7); hold on
% pcolor(bry_test_read.u_south(:,:,1)-squeeze(ini_test_read.u(:,1,:)));
% clim([-1 1]*0.1);colorbar
% title("south")

% ax(5) = nexttile; hold on
% pcolor(bry_test_read.v_east(:,:,1)-squeeze(ini_test_read.v(end,:,:)));
% clim([-1 1]*0.1);colorbar
% title("east")

% ax(6) = nexttile; hold on
% pcolor(bry_test_read.v_west(:,:,1)-squeeze(ini_test_read.v(1,:,:)));
% clim([-1 1]*0.1);colorbar
% title("west")

% ax(7) = nexttile; hold on
% pcolor(bry_test_read.v_north(:,:,1)-squeeze(ini_test_read.v(:,end,:)));
% clim([-1 1]*0.1);colorbar
% title("north")

% ax(8) = nexttile; hold on
% pcolor(bry_test_read.v_south(:,:,1)-squeeze(ini_test_read.v(:,1,:)));
% clim([-1 1]*0.1);colorbar
% title("south")

% title(ti,"boundary / inital u (left) v (right) (m/s) different")
% saveas(gcf,"boundary_test_vel_diff.fig")
% saveas(gcf,"boundary_test_vel_diff.jpg")

% check temp at boundary
cd(figure_path)
figure; clf; hold on
colormap(thermal)
ti = tiledlayout(4,1); ti.Padding = "compact"; ti.TileSpacing = "tight";
ax(1) = nexttile; hold on
contour(bry_test_read.temp_east(:,:,1)',1:1:30,"color","k");
contour(squeeze(ini_test_read.temp(end,:,:))',1:1:30,"linestyle","--","color","r");
title("east")

ax(2) = nexttile; hold on
contour(bry_test_read.temp_west(:,:,1)',1:1:30,"color","k");
contour(squeeze(ini_test_read.temp(1,:,:))',1:1:30,"linestyle","--","color","r");
title("west")

ax(3) = nexttile; hold on
contour(bry_test_read.temp_north(:,:,1)',1:1:30,"color","k");
contour(squeeze(ini_test_read.temp(:,end,:))',1:1:30,"linestyle","--","color","r");
title("north")

ax(4) = nexttile; hold on
contour(bry_test_read.temp_south(:,:,1)',1:1:30,"color","k");
contour(squeeze(ini_test_read.temp(:,1,:))',1:1:30,"linestyle","--","color","r");
title("south")
title(ti,"boundary / inital temp match")
saveas(gcf,"boundary_test_temp.jpg")

% check temp at boundary
cd(figure_path)
figure; clf; hold on
colormap(thermal)
ti = tiledlayout(4,2); ti.Padding = "compact"; ti.TileSpacing = "tight";
ax(1) = nexttile; hold on
contourf(bry_test_read.temp_east(:,:,1)',1:1:30,...
     'LineStyle','none');
title("east boundary"); colorbar

ax(2) = nexttile; hold on
contourf(squeeze(ini_test_read.temp(end,:,:))',...
    1:1:30, 'LineStyle','none');
title("east initial"); colorbar
clim(ax,[-1 1]*1.5)

ax(3) = nexttile; hold on
contourf(bry_test_read.temp_west(:,:,1)',1:1:30,...
     'LineStyle','none');
title("west boundary"); colorbar

ax(4) = nexttile; hold on
contourf(squeeze(ini_test_read.temp(1,:,:))',...
    1:1:30, 'LineStyle','none');
title("west initial"); colorbar
clim(ax,[-1 1]*1.5)

ax(5) = nexttile; hold on
contourf(bry_test_read.temp_north(:,:,1)',1:1:30,...
     'LineStyle','none');
title("north boundary"); colorbar

ax(6) = nexttile; hold on
contourf(squeeze(ini_test_read.temp(:,end,:))',...
    1:1:30, 'LineStyle','none');
title("north initial"); colorbar
clim(ax,[-1 1]*1.5)

ax(7) = nexttile; hold on
contourf(bry_test_read.temp_south(:,:,1)',1:1:30,...
     'LineStyle','none');
title("south boundary"); colorbar

ax(8) = nexttile; hold on
contourf(squeeze(ini_test_read.temp(:,1,:))',...
    1:1:30, 'LineStyle','none');
title("south initial"); colorbar
title(ti,"boundary / inital temp match")
clim(ax,[0 30])
saveas(gcf,"boundary_test_temp_cf.jpg")
clim(ax,[25 30])
saveas(gcf,"boundary_test_temp_cf_cz.jpg")


%% check initial
zeta0 = ini_test_read.zeta;
u0 = ini_test_read.u;
v0 = ini_test_read.v;
fprintf('zeta range: %f to %f\n', min(zeta0(:)), max(zeta0(:)));
fprintf('u range: %f to %f\n', min(u0(:)), max(u0(:)));
[maxu, idx] = max(abs(u0(:)));
[i,j,k] = ind2sub(size(u0), idx);
fprintf('max |u| = %f at i=%d,j=%d,k=%d\n', maxu, i,j,k);
fprintf('v range: %f to %f\n', min(v0(:)), max(v0(:)));
[maxv, idx] = max(abs(v0(:)));
[i,j,k] = ind2sub(size(v0), idx);
fprintf('max |v| = %f at i=%d,j=%d,k=%d\n', maxv, i,j,k);


%% problematic grid i = 714 j = 2509 k = 38
blowup = [714 2509 38];
cd(figure_path)
figure; clf; hold on
clear ax
ti = tiledlayout(3,3); 
ti.Padding = "compact"; ti.TileSpacing = "tight";
for i = blowup(1) - 1 : 1 : blowup(1) + 1
    for j = blowup(2) - 1 : 1 : blowup(2) + 1
        disp(append("(i,j)=(",num2str(i),",",num2str(j),")"))
        ax(i,j) = nexttile; hold on
        plot(squeeze(ini_test_read.temp(i,j,:)),...
            squeeze(ROMS_z(i,j,:)),"o-");
        xl = xlim;
        line(xl,ROMS_z(i,j,blowup(3))*[1 1])
        title(append("(i,j)=(",num2str(i),",",num2str(j),")"))
    end
end
saveas(gcf,"initial_blowup_temp.jpg")

figure; clf; hold on
clear ax
ti = tiledlayout(1,1); 
ti.Padding = "compact"; ti.TileSpacing = "tight";
nexttile; hold on
for i = blowup(1) - 1 : 1 : blowup(1) + 1
    for j = blowup(2) - 1 : 1 : blowup(2) + 1
        disp(append("(i,j)=(",num2str(i),",",num2str(j),")"))
        plot(squeeze(ini_test_read.temp(i,j,:)),...
            squeeze(ROMS_z(i,j,:)),"o-");
        xl = xlim;
        line(xl,ROMS_z(i,j,blowup(3))*[1 1])
    end
end
saveas(gcf,"initial_blowup_temp2.jpg")

temp0 = ini_test_read.temp;
figure;
ti = tiledlayout(3,3); 
ti.Padding = "compact"; ti.TileSpacing = "tight";
for di = -1:1
    for dj = -1:1
        nexttile; hold on % adjust indexing to taste
        plot(squeeze(temp0(714+di, 2509+dj, :)), 1:size(temp0,3), 'o-');
        title(sprintf('(i,j)=(%d,%d)', 714+di, 2509+dj));
    end
end
saveas(gcf,"initial_blowup_temp3.jpg")

u0 = ini_test_read.u;  v0 = ini_test_read.v;
figure; ti = tiledlayout(3,3); ti.Padding="compact"; ti.TileSpacing="tight";
for di = -1:1
  for dj = -1:1
    nexttile; hold on
    plot(squeeze(u0(714+di, 2509+dj, :)), 1:size(u0,3), 'o-');
    plot(squeeze(v0(714+di, 2509+dj, :)), 1:size(v0,3), 'x-');
    title(sprintf('(i,j)=(%d,%d)', 714+di, 2509+dj));
    legend('u','v',"location","southeast");
  end
end
saveas(gcf,"initial_blowup_vel.jpg")

u0 = ini_test_read.u;  v0 = ini_test_read.v;
figure; ti = tiledlayout(1,2); ti.Padding="compact"; ti.TileSpacing="tight";
nexttile; hold on
for di = -1:1
  for dj = -1:1
    plot(squeeze(u0(714+di, 2509+dj, :)), 1:size(u0,3), 'o-');
  end
end
nexttile; hold on
for di = -1:1
    for dj = -1:1
      plot(squeeze(v0(714+di, 2509+dj, :)), 1:size(v0,3), 'x-');
    end
  end
saveas(gcf,"initial_blowup_vel2.jpg")

pm = grd_test_read.pm;
pn = grd_test_read.pn;
fprintf('dx=%.1f m, dy=%.1f m at (714,2509)\n', 1/pm(714,2509), 1/pn(714,2509));
fprintf('dx=%.1f m, dy=%.1f m at (715,2509)\n', 1/pm(715,2509), 1/pn(715,2509));
fprintf('dx=%.1f m, dy=%.1f m at (714,2510)\n', 1/pm(714,2510), 1/pn(714,2510));
fprintf('dx=%.1f m, dy=%.1f m at (713,2508)\n', 1/pm(713,2508), 1/pn(713,2508));


k = 38;
i0 = 714; j0 = 2509;
window = 20;

u_slice = squeeze(u0(i0-window:i0+window, j0-window:j0+window, k));
v_slice = squeeze(v0(i0-window:i0+window, j0-window:j0+window, k));
t_slice = squeeze(temp0(i0-window:i0+window, j0-window:j0+window, k));

cd(figure_path)
figure;
subplot(1,3,1); imagesc(u_slice); 
colorbar; title('u at k=38'); daspect([1 1 1])
subplot(1,3,2); imagesc(v_slice); 
colorbar; title('v at k=38');daspect([1 1 1])
subplot(1,3,3); imagesc(t_slice); 
colorbar; title('temp at k=38');daspect([1 1 1])
saveas(gcf,"initial_blowup_window.jpg")

h_slice = grd_test_read.h(i0-window:i0+window, j0-window:j0+window);
figure; imagesc(h_slice); ;daspect([1 1 1])
colorbar; title('h (bathymetry) near blowup point');
saveas(gcf,"initial_blowup_bathwindow.jpg")

h_slice = ROMS_z(i0-window:i0+window, j0-window:j0+window,blowup(3));
figure; imagesc(h_slice); ;daspect([1 1 1])
colorbar; title('z grid near blowup point');
saveas(gcf,"initial_blowup_z38window.jpg")

%% ri # check
g = 9.81; rho0 = 1027.5;
k_range = 34:42;  % bracket k=38

salt0 = ini_test_read.salt;
zc = ROMS_z;
u_col = squeeze(u0(i0,j0,k_range));
v_col = squeeze(v0(i0,j0,k_range));
t_col = squeeze(temp0(i0,j0,k_range));
s_col = squeeze(salt0(i0,j0,k_range));  % if available
z_col = squeeze(zc(i0,j0,k_range));      % or however you've stored z-levels
p_col = -z_col;  

lon0 = grd_test_read.lon_rho(i0,j0);
lat0 = grd_test_read.lat_rho(i0,j0);
SA = gsw_SA_from_SP(s_col, p_col, lon0, lat0);   % Absolute Salinity
CT = gsw_CT_from_pt(SA, t_col);
[N2, p_mid] = gsw_Nsquared(SA, CT, p_col, lat0);

dz = diff(z_col);
dudz = diff(u_col)./dz;
dvdz = diff(v_col)./dz;
shear2 = dudz.^2 + dvdz.^2;

Ri = N2 ./ shear2;
disp(table(p_mid, N2, shear2, Ri))

%% new blow up points check
%% problematic grid i = 2011 j = 2511 k = 98
i_blow = 2011,j_blow = 2511,k_blow=98
casenum = 9
files.ini_test_read = ini_test_read;
files.grd_test_read = grd_test_read;
files.ROMS_z = ROMS_z;
blowup_test(i_blow,j_blow,k_blow,figure_path,casenum,files)