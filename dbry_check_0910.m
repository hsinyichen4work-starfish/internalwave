clear; clc;
addpath(genpath('/home/hsinyi/Documents/CODE/matlab_funtion'), '-end');
%%
balance = cmocean('balance');
%%
dx = 900;
cgrid_name = ['roms_grd_',num2str(dx),'m.nc'];
dbry_name = ['roms_dbry_flux_',num2str(dx),'m*.nc'];
dbry_mat_name = ['bryfile_dynamic',num2str(dx),'*.mat'];
quiver_fod = ['quiver_plot_',num2str(dx),'m'];
dbry_path = '/home/hsinyi/roms_data/bry_dynamic_flux_63/';
child_grid_path = '/home/hsinyi/roms_data/grid/';
child_bry_path = '/home/hsinyi/roms_data/bry_63/';
flux_out_path = '/home/hsinyi/roms_data/bry_dynamic_flux_63/'; 
figure_path = '/home/hsinyi/figure/20260904dynamic_bry/';
dbry_mat_path = '/home/hsinyi/matlab_file/dbry_saving/';
nchose = 400;   % along-boundary index for single-point Fx/Fy time series check (see bry_check_timeplot.m)
%%
cgrid = read_nc_fun([child_grid_path,cgrid_name]);
disp(['read in',cgrid_name ])
cgrid.lon_rho(cgrid.lon_rho>180) = cgrid.lon_rho(cgrid.lon_rho>180) -360;
t1 = datenum('1994/01/01');
%%
cd(dbry_path)
file_list = dir([dbry_path,dbry_name]);
file_mat_list = dir([dbry_mat_path,dbry_mat_name]);
% dir() order isn't guaranteed to already be chronological -- both
% filenames embed the date in a fixed-width, sortable form
% (roms_dbry_flux_<dx>m_yyyymmddHH.nc / bryfile_dynamic<dx>_yyyymmdd.mat),
% so sort explicitly to make file_list(t)/file_mat_list(t) correspond to
% the same calendar day below.
[~, idx] = sort({file_list.name});     file_list     = file_list(idx);
[~, idx] = sort({file_mat_list.name}); file_mat_list = file_mat_list(idx);
if length(file_list) ~= length(file_mat_list)
    error('file_list (%d files) and file_mat_list (%d files) counts differ -- check %s vs %s', ...
        length(file_list), length(file_mat_list), dbry_name, dbry_mat_name);
end

% theta_s/theta_b/hc aren't stored in the daily bry-flux mat file, so pull
% them once from one of the original child bry files (same as dbry_make.m
% did) -- constant across days, so hoisted outside the day loop below.
probe_list = dir([child_bry_path,'roms_bry_',num2str(dx),'m_*.nc']);
probe = read_nc_fun([child_bry_path,probe_list(1).name]);
theta_s = probe.theta_s; theta_b = probe.theta_b; hc = probe.hc;
clear probe
%%
for t = 1 : length(file_list)
    dbry_nc  = read_nc_fun(fullfile(file_list(t).folder, file_list(t).name));
    dbry_mat = load(fullfile(file_mat_list(t).folder, file_mat_list(t).name));

    %% check p_prime/u_prime/v_prime are thickness-weighted depth integral = 0
    % by definition (depth_mean_bar_cal.m): var_prime = var - var_bar, where
    % var_bar is the thickness-weighted mean over the vertical (sigma) grid,
    % so sum(var_prime .* thickness, depth) must be ~0 at every (along,time).
    dirstr = ["north","south","east","west"];
    vars_to_check = ["p_prime","u_prime","v_prime"];

    for j = 1:length(dirstr)
        dc = char(dirstr(j));
        bathc = dbry_mat.([dc,'_bathc'])(:);
        ssh   = dbry_mat.([dc,'_ssh']);
        nt    = size(ssh,2);
        nz    = size(dbry_mat.([dc,'_p_prime']),2);

        z_w    = zlevs3(repmat(bathc,1,nt), ssh, theta_s, theta_b, hc, nz, 'w', 'new2008');
        lthick = diff(permute(z_w,[2 1 3]),1,2);   % (nalong, nz, nt), matches *_prime shape

        fprintf('--- %s boundary ---\n', dc);
        for k = 1:length(vars_to_check)
            vname = char(vars_to_check(k));
            var = double(dbry_mat.([dc,'_',vname]));
            depth_int  = squeeze(sum(var .* lthick, 2));                    % should be ~0
            depth_scale = squeeze(sum(abs(var) .* lthick, 2));              % typical magnitude
            rel = abs(depth_int) ./ (depth_scale + eps);
            fprintf('  %-8s max|depth-int| = %.3e   max relative = %.3e\n', ...
                vname, max(abs(depth_int(:))), max(rel(:)));
        end
    end

    %% check nc up_west/up_east/vp_south/vp_north == mat Fx/Fy divided by rho0
    % dbry_make.m writes the flux nc file as src_full/rho0 (rho0-normalized),
    % while the daily mat file keeps the raw (non-normalized) Fx/Fy -- see
    % write_daily_outputs in dbry_make.m. rho0 is also stored in the mat file.
    rho0_check = dbry_mat.rho0;
    fprintf('rho0 = %.4f (from dbry_mat.rho0)\n', rho0_check);

    fx_map = struct('west','up_west', 'east','up_east');
    fy_map = struct('south','vp_south', 'north','vp_north');

    dirs_fx = ["west","east"];
    for j = 1:length(dirs_fx)
        dc = char(dirs_fx(j));
        ncvar   = fx_map.(dc);
        nc_val  = dbry_nc.(ncvar);
        mat_val = dbry_mat.([dc,'_Fx']) / rho0_check;
        if ~isequal(size(nc_val), size(mat_val))
            warning('%s: size mismatch nc %s %s vs mat %s_Fx %s -- skipping', ...
                dc, ncvar, mat2str(size(nc_val)), dc, mat2str(size(mat_val)));
            continue
        end
        diff_val = nc_val - mat_val;
        rel = abs(diff_val) ./ (abs(mat_val) + eps);
        fprintf('%-6s %-8s max|diff| = %.3e   max relative = %.3e\n', ...
            dc, ncvar, max(abs(diff_val(:))), max(rel(:)));
    end

    dirs_fy = ["south","north"];
    for j = 1:length(dirs_fy)
        dc = char(dirs_fy(j));
        ncvar   = fy_map.(dc);
        nc_val  = dbry_nc.(ncvar);
        mat_val = dbry_mat.([dc,'_Fy']) / rho0_check;
        if ~isequal(size(nc_val), size(mat_val))
            warning('%s: size mismatch nc %s %s vs mat %s_Fy %s -- skipping', ...
                dc, ncvar, mat2str(size(nc_val)), dc, mat2str(size(mat_val)));
            continue
        end
        diff_val = nc_val - mat_val;
        rel = abs(diff_val) ./ (abs(mat_val) + eps);
        fprintf('%-6s %-8s max|diff| = %.3e   max relative = %.3e\n', ...
            dc, ncvar, max(abs(diff_val(:))), max(rel(:)));
    end

    %%
    [east_Fx_geo, east_Fy_geo] = vel_rot(dbry_mat.east_Fx, dbry_mat.east_Fy, ...
        repmat(rad2deg(dbry_mat.east_angc),length(dbry_mat.time),1)', 'grid2geo');
    [west_Fx_geo, west_Fy_geo] = vel_rot(dbry_mat.west_Fx, dbry_mat.west_Fy, ...
        repmat(rad2deg(dbry_mat.west_angc),length(dbry_mat.time),1)',  'grid2geo');
    [north_Fx_geo, north_Fy_geo] = vel_rot(dbry_mat.north_Fx, dbry_mat.north_Fy, ...
        repmat(rad2deg(dbry_mat.north_angc),1,length(dbry_mat.time)),  'grid2geo');
    [south_Fx_geo, south_Fy_geo] = vel_rot(dbry_mat.south_Fx, dbry_mat.south_Fy, ...
        repmat(rad2deg(dbry_mat.south_angc),1,length(dbry_mat.time)),  'grid2geo');
    %%
    cd(figure_path)
    if ~isfolder(quiver_fod); mkdir(quiver_fod); end; cd(quiver_fod)
    s = 10^-4;
    frame_step = 1;              % plot every Nth time step (raise to speed up / shrink file)
    for t_idx = 1:frame_step:length(dbry_mat.time);
        figure(1); clf; hold on
        grid_boundary_plot(cgrid.lon_rho,cgrid.lat_rho,[1 1 1]*0,0.5)
        daspect([1 1 1])
        h_east  = quiver(dbry_mat.east_lon(:), dbry_mat.east_lat(:),  s*east_Fx_geo(:,t_idx),  s*east_Fy_geo(:,t_idx),  "off");
        h_west  = quiver(dbry_mat.west_lon(:), dbry_mat.west_lat(:),  s*west_Fx_geo(:,t_idx),  s*west_Fy_geo(:,t_idx),  "off");
        h_south = quiver(dbry_mat.south_lon(:),dbry_mat.south_lat(:), s*south_Fx_geo(:,t_idx), s*south_Fy_geo(:,t_idx), "off");
        h_north = quiver(dbry_mat.north_lon(:),dbry_mat.north_lat(:), s*north_Fx_geo(:,t_idx), s*north_Fy_geo(:,t_idx), "off");
        quiver(-49,7,s*1*10^4,s*0,"color","k");
        text(-49,7.2,"10kW/m")
        ti = title(datestr(dbry_mat.time(t_idx) + t1));
        saveas(gcf,['flux_quiver_',datestr(dbry_mat.time(t_idx) + t1,"yyyymmddHH"),'.jpg'])
        disp(['save flux_quiver_',datestr(dbry_mat.time(t_idx) + t1,"yyyymmddHH"),'.jpg'])
    end
end

%% load & concatenate every daily mat file into one continuous time series
% per boundary, so figures 2/3 below show the whole ~90 day record in a
% single pcolor per tile, instead of looping pcolor calls per day (which
% would mean re-tiling/re-coloring/re-limiting issues, not just clf).
% NOTE: runs ONCE, after the per-day loop above -- it was previously nested
% inside that loop, which reloaded and rebuilt the whole series on every
% single day iteration (~N times more file I/O than needed).
dirstr = ["north","south","east","west"];
% along-boundary coordinate: north/south run E-W (lon varies), east/west
% run N-S (lat varies) -- use whichever one actually varies along each
% boundary instead of always using lon.
along_field = struct('north','lon', 'south','lon', 'east','lat', 'west','lat');

need_vars = "time";
for j = 1:length(dirstr)
    dc = dirstr(j);
    need_vars = [need_vars, dc+"_Fx", dc+"_Fy", dc+"_"+along_field.(char(dc))]; %#ok<AGROW>
end
need_vars = cellstr(need_vars);

bry_all = struct();
for j = 1:length(dirstr)
    dc = char(dirstr(j));
    bry_all.(dc).time = [];
    bry_all.(dc).Fx   = [];
    bry_all.(dc).Fy   = [];
end

for tt = 1:length(file_mat_list)
    dm = load(fullfile(file_mat_list(tt).folder, file_mat_list(tt).name), need_vars{:});
    for j = 1:length(dirstr)
        dc = char(dirstr(j));
        bry_all.(dc).time = [bry_all.(dc).time, dm.time(:)' + t1];   % -> real datenum
        bry_all.(dc).Fx   = [bry_all.(dc).Fx,   dm.([dc,'_Fx'])];
        bry_all.(dc).Fy   = [bry_all.(dc).Fy,   dm.([dc,'_Fy'])];
    end
    if tt == 1
        for j = 1:length(dirstr)
            dc = char(dirstr(j));
            bry_all.(dc).along = dm.([dc,'_',along_field.(dc)])(:);
        end
    end
    if mod(tt,10) == 0 || tt == length(file_mat_list)
        fprintf('loaded %d/%d daily mat files\n', tt, length(file_mat_list));
    end
end

%%
cd(figure_path)
figure(2); clf; hold on
til = tiledlayout(2,2); til.TileSpacing = 'compact'; til.Padding = 'compact';

ax = gobjects(1,length(dirstr));
for j = 1:length(dirstr)
    dc = char(dirstr(j));
    ax(j) = nexttile; hold on
    along = bry_all.(dc).along;
    mypcolor(repmat(bry_all.(dc).time, length(along), 1), ...
        repmat(along, 1, length(bry_all.(dc).time)), ...
        abs(bry_all.(dc).Fx + 1i * bry_all.(dc).Fy));
    colorbar
    title(dc)
    datetick(ax(j),'x','mmmdd','keeplimits')
end

clim(ax,[0 1]*15000); linkaxes(ax,'x')
saveas(gcf,"flux_mag_check.jpg")
saveas(gcf,"flux_mag_check.fig")

%% figure 3: signed boundary-normal flux only (Fx for east/west, Fy for north/south)
cd(figure_path)
figure(3); clf; hold on
til3 = tiledlayout(2,2); til3.TileSpacing = 'compact'; til3.Padding = 'compact';

% boundary-normal component only: east/west boundaries face the x/u
% direction (Fx), north/south boundaries face the y/v direction (Fy)
normal_field = struct('north','Fy',  'south','Fy',  'east','Fx',  'west','Fx');

ax3 = gobjects(1,length(dirstr));
for j = 1:length(dirstr)
    dc = char(dirstr(j));
    ax3(j) = nexttile; hold on
    along = bry_all.(dc).along;
    mypcolor(repmat(bry_all.(dc).time, length(along), 1), ...
        repmat(along, 1, length(bry_all.(dc).time)), ...
        bry_all.(dc).(normal_field.(dc)));   % signed, not abs
    colorbar
    colormap(ax3(j), balance)
    title([dc,' (',normal_field.(dc),')'])
    datetick(ax3(j),'x','mmmdd','keeplimits')
end

clim(ax3,[-1 1]*15000); linkaxes(ax3,'x')
saveas(gcf,"flux_normal_signed.jpg")
saveas(gcf,"flux_normal_signed.fig")

%% figure 4: Fx/Fy time series at a single along-boundary point (nchose)
% same idea as the single check-point time series plots in bry_check_timeplot.m
% (e.g. zeta_child at cbry.zeta_south(nchose,:)), applied to the concatenated
% flux series bry_all built above instead of re-reading files.
cd(figure_path)
nchose = 400;
figure(4); clf; hold on
til4 = tiledlayout(2,2); til4.TileSpacing = 'compact'; til4.Padding = 'compact';

ax4 = gobjects(1,length(dirstr));
for j = 1:length(dirstr)
    dc = char(dirstr(j));
    along = bry_all.(dc).along;
    if nchose > length(along)
        error('nchose (%d) exceeds %s boundary length (%d)', nchose, dc, length(along));
    end
    ax4(j) = nexttile; hold on
    plot(bry_all.(dc).time, bry_all.(dc).Fx(nchose,:), ...
        "color","r","LineWidth",1,"Marker","o","MarkerSize",4,"DisplayName","Fx")
    plot(bry_all.(dc).time, bry_all.(dc).Fy(nchose,:), ...
        "color","b","LineWidth",1,"Marker","o","MarkerSize",4,"DisplayName","Fy")
    title(sprintf('%s (along-idx %d)', dc, nchose))
    datetick(ax4(j),'x','mmmdd','keeplimits')
    legend show
end
linkaxes(ax4,'x')
saveas(gcf,sprintf('flux_timeseries_nchose%d.jpg',nchose))
saveas(gcf,sprintf('flux_timeseries_nchose%d.fig',nchose))
%%
figure
plot(bry_all.north.along,mean(bry_all.north.Fy,2))
saveas(gcf,"test.jpg")