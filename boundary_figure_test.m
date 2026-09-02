clear; clc;
addpath(genpath('/home/hsinyi/Documents/CODE/matlab_funtion'));
%%
dx = 900;
parent_grid = '/home/mbui/ModelOutput/NCOM/grid/ohgrd_2.nc';
nc_path_ini_bry = '/home/hsinyi/roms_data/bry/bry_read_nc/';
child_grid_path = '/home/hsinyi/roms_data/grid/';
child_bry_path = '/home/hsinyi/roms_data/bry/';
figure_path = '/home/hsinyi/figure/20260821_debug_fix';
cgrid_name = ['roms_grd_',num2str(dx),'m.nc'];

dating = datenum("20220822","yyyymmdd") : datenum("20220901","yyyymmdd");
t1 = datenum(1900,12,31,0,0,0); t2 = datenum(1994,1,1,0,0,0);
pgrid = read_nc_fun(parent_grid);
cgrid = read_nc_fun([child_grid_path,cgrid_name]);
%%
cd(nc_path_ini_bry)
fod = string(datestr(dating,"yyyymmddHH"));
lthick = ncread(append(nc_path_ini_bry,fod(1),'_lthick.nc'),"layer_thickness");
lat = ncread(append(nc_path_ini_bry,fod(1),'_lthick.nc'),"Latitude");
lon = ncread(append(nc_path_ini_bry,fod(1),'_lthick.nc'),"Longitude");
NCOM_nc.layer_thickness = lthick;
[zs] = NCOM_zgrid(NCOM_nc);
z_grid = permute(zs,[3 2 1]);
if min(diff(mean(z_grid,[1,2]))) < 0
    error("z should be NEGATIVE down, INCREASING with index (z(1)=deepest ... z(end)=~0)")
end

%% Prepare the parent (HYCOM) side
lonp = lon; latp = lat;   % 2D, HYCOM grid (Mp,Lp)
maskp = pgrid.mask;     % 2D, 1=ocean, 0=land (Mp,Lp)
zp = permute(zs,[1 3 2]) ;         % 3D (Np,Mp,Lp), HYCOM depth levels, NEGATIVE down, ASCENDING order
             % (k=1 is deepest, k=Np is at/near the surface)

%% Prepare the child (ROMS boundary) side
Lc = length(cgrid.lon_rho(1,:));
lonc = repmat(reshape(cgrid.lon_rho(1,:), [1 Lc]), 2, 1);   % (2,Lc) -- duplicated row trick
latc = repmat(reshape(cgrid.lat_rho(1,:), [1 Lc]), 2, 1);   % (2,Lc)
h_c  = repmat(reshape(cgrid.h(1,:),       [1 Lc]), 2, 1);   % (2,Lc)

%%
cbry_name = ['roms_bry_',num2str(dx),'m_',datestr(dating(1),"yyyymmddHH"),'.nc'];
cbry = read_nc_fun([child_bry_path,cbry_name]);
theta_s = cbry.theta_s; theta_b = cbry.theta_b; 
hc = cbry.hc; N = size(cbry.temp_south,2);
%% Prepare the ssh zeta
[elem2d, coef2d, nnel] = get_tri_coef(lonp, latp, lonc, latc, maskp);
zeta = ncread(append(nc_path_ini_bry,datestr(dating(1),"yyyymmddHH"),'_ssh.nc'),"ssh");
zetap = zeta; zetap(maskp==0) = zetap(nnel(maskp==0));   % fill land first, as always
zeta_c = sum(coef2d .* zetap(elem2d), 3);   % shape (1,Lc) for a boundary line

%% Prepare the child (ROMS boundary) side z grid
[zc, Cs] = zlevs3(h_c, zeta_c, theta_s, theta_b, hc, N, 'r', 'new2008');
A = get_hv_coef(zp, zc, coef2d, elem2d, lonp, latp, lonc, latc);
%% Step 3 — Fill land points in the parent data (don't skip this)
temp_p = ncread(append(nc_path_ini_bry,datestr(dating(1),"yyyymmddHH"),'_ts.nc'),"layer_temperature");
[Mp,Lp,Np,Ntime] = size(temp_p);
[Nc,Mc,Lc] = size(zc);  

for it = 1:Ntime
    temp_slice = permute(squeeze(temp_p(:,:,:,it)), [3 1 2]);  % (Np,Mp,Lp)

    temp_filled = temp_slice;
    for k = 1:Np
        layer = squeeze(temp_slice(k,:,:));
        layer(maskp==0) = layer(nnel(maskp==0));
        temp_filled(k,:,:) = layer;
    end

    % ... then apply A (built once, outside this loop, if zc/zeta held fixed)
    temp_c = reshape(A * reshape(temp_filled, Np*Mp*Lp,1), Nc,Mc,Lc);
    temp_c  = squeeze(temp_c(:,1,:)); 
end

%%
