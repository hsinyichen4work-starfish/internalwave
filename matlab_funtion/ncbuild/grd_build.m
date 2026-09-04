%% Built the grid & check the size
[mid,rot_ang] = gid_middle(mid_iter);
[grd,actual_dx_APPROX,actual_dy_APPROX] = grid_setting(mid,rot_ang,dx,nx,ny);
disp(append(num2str(dx),"m : actual_dx_APPROX = ",num2str(actual_dx_APPROX),...
    ", actual_dy_APPROX = ",num2str(actual_dy_APPROX)));
grdlon = rad2deg(grd.lon4)-360;
grdlat = rad2deg(grd.lat4);
%% bathymetry for interpolation
gebco = read_nc_fun([bath_path,'GEBCO_2025I2021.nc']);
small = 0.1;
lon_dum = gebco.Longitude >= min(grdlon,[],"all") - small & gebco.Longitude <= max(grdlon,[],"all") + small;
lat_dum = gebco.Latitude >= min(grdlat,[],"all") - small & gebco.Latitude <= max(grdlat,[],"all") + small;
[topo.lon, topo.lat] = meshgrid(gebco.Longitude(lon_dum), ...
     gebco.Latitude(lat_dum));
topo.Z = gebco.elevation(lon_dum,lat_dum)';
%% parent grid bath
pgrid = read_nc_fun(parent_grid);
if mean(pgrid.h(pgrid.mask == 1),"omitmissing") < 0
    pgrid.h = -pgrid.h;
end
%%
[grd] = bathy_interp(topo,grd);
grd_nc = make_roms_ncgrid(grd,grd_name,mid,rot_ang,dx,nx,ny,smooth_var,grid_path);
cd(path_figure)
[grd_nc, diag] = match_boundary_topo(pgrid, grd_nc, [1 1 1 1], 4,5);
saveas(gcf,append("match_topo_check_",num2str(dx),".fig"))
saveas(gcf,append("match_topo_check_",num2str(dx),".jpg"))
grid_boundary_match_figure