clear; clc
addpath(genpath('/home/hsinyi/Documents/CODE/matlab_funtion/'));

%% path setting
forcing_path = '/home/hsinyi/roms_data/frc/';
forcing_pathnc = '/home/hsinyi/roms_data/frc/frc_read_nc/';
grid_path = '/home/hsinyi/roms_data/grid/';
figure_path = '/home/hsinyi/figure/20260817_frc_test/';

gridfile = 'roms_grd_300m.nc';
frc_file = 'roms_frc_300m_2022082200.nc';

%%
thermal = cmocean('thermal');
balance = cmocean('balance');
speed = cmocean('speed');

%% roms nc file read
frc_test_read = read_nc_fun([forcing_path,frc_file]);
grd_test_read = read_nc_fun([grid_path,gridfile]);

%% ncom nc file read
NCOM_WIND = read_nc_fun([forcing_pathnc,'2022082200_wnd.nc']);
NCOM_GRID = read_nc_fun([forcing_pathnc,'2022082200_lthick.nc']);
NCOM_FLUX = read_nc_fun([forcing_pathnc,'2022082200_flx.nc']);
NCOM_PRES = read_nc_fun([forcing_pathnc,'2022082200_pres.nc']);

%%
grd_test_read.lon_rho(grd_test_read.lon_rho>180) =  ...
    grd_test_read.lon_rho(grd_test_read.lon_rho>180)-360; % make lon east-west himisphere
frc_time = (frc_test_read.sms_time) + datenum('1994-01-01');
nc_time = NCOM_WIND.MT + datenum('1900-12-31');

%% ploting to check
cd(figure_path)
mv = VideoWriter('surf_heatflux_check_20220822', 'Motion JPEG AVI');
mv.FrameRate = 5;
open(mv);
for t = 1 : size(frc_time,1)
    disp(append("time : ",datestr(frc_time(t))))
    figure; clf; hold on
    colormap(balance)
    ti = tiledlayout(1,2); ti.Padding = "compact"; ti.TileSpacing = "tight";
    ax(1) = nexttile; hold on
    mypcolor(NCOM_GRID.Longitude,NCOM_GRID.Latitude,NCOM_FLUX.heaflx(:,:,t))
    grid_boundary_plot(grd_test_read.lon_rho,grd_test_read.lat_rho,"k",2)
    colorbar; daspect([1 1 1])
    title("NCOM data")

    ax(2) = nexttile; hold on
    mypcolor(grd_test_read.lon_rho,grd_test_read.lat_rho,frc_test_read.shflux(:,:,t))
    colorbar; daspect([1 1 1])
    title("ROMS inital nc file")
    title(ti,append("surface heat flux (^\circ C m s^{-1})",...
        " for time : ",datestr(frc_time(t))))

    clim(ax,[-1 1]*10^-4); linkaxes(ax,'xy'); 
    xlim(max_min(grd_test_read.lon_rho))
    ylim(max_min(grd_test_read.lat_rho))
    saveas(gcf,append("forcing_test_shflux_",datestr(frc_time(t)) ,".jpg"))
    frame = getframe(gcf);
    writeVideo(mv,frame);
end
close(mv)


%% ploting to check
cd(figure_path)
mv = VideoWriter('surf_saltflux_check_20220822', 'Motion JPEG AVI');
mv.FrameRate = 5;
open(mv);
for t = 1 : size(frc_time,1)
    disp(append("time : ",datestr(frc_time(t))))
    figure; clf; hold on
    colormap(balance)
    ti = tiledlayout(1,2); ti.Padding = "compact"; ti.TileSpacing = "tight";
    ax(1) = nexttile; hold on
    mypcolor(NCOM_GRID.Longitude,NCOM_GRID.Latitude,NCOM_FLUX.salflx(:,:,t))
    grid_boundary_plot(grd_test_read.lon_rho,grd_test_read.lat_rho,"k",2)
    colorbar; daspect([1 1 1])
    title("NCOM data")

    ax(2) = nexttile; hold on
    mypcolor(grd_test_read.lon_rho,grd_test_read.lat_rho,frc_test_read.swflux(:,:,t))
    colorbar; daspect([1 1 1])
    title("ROMS inital nc file")
    title(ti,append("surface salt flux (PSU m s^{-1})",...
        " for time : ",datestr(frc_time(t))))

    clim(ax,[-1 1]*2*10^-5); linkaxes(ax,'xy'); 
    xlim(max_min(grd_test_read.lon_rho))
    ylim(max_min(grd_test_read.lat_rho))
    saveas(gcf,append("forcing_test_swflux_",datestr(frc_time(t)) ,".jpg"))
    frame = getframe(gcf);
    writeVideo(mv,frame);
end
close(mv)

%% ploting to check
cd(figure_path)
mv = VideoWriter('surf_shortwave_radi_check_20220822', 'Motion JPEG AVI');
mv.FrameRate = 5;
open(mv);
for t = 1 : size(frc_time,1)
    disp(append("time : ",datestr(frc_time(t))))
    figure; clf; hold on
    colormap(thermal)
    ti = tiledlayout(1,2); ti.Padding = "compact"; ti.TileSpacing = "tight";
    ax(1) = nexttile; hold on
    mypcolor(NCOM_GRID.Longitude,NCOM_GRID.Latitude,NCOM_FLUX.solflx(:,:,t))
    grid_boundary_plot(grd_test_read.lon_rho,grd_test_read.lat_rho,"k",2)
    colorbar; daspect([1 1 1])
    title("NCOM data")

    ax(2) = nexttile; hold on
    mypcolor(grd_test_read.lon_rho,grd_test_read.lat_rho,frc_test_read.swrad(:,:,t))
    colorbar; daspect([1 1 1])
    title("ROMS inital nc file")
    title(ti,append("shortwave radiation (^\circ C m s^{-1})",...
        " for time : ",datestr(frc_time(t))))

    clim(ax,[0 1]*max(frc_test_read.swrad(:,:,t),[],"all")+10^-6); linkaxes(ax,'xy'); 
    xlim(max_min(grd_test_read.lon_rho))
    ylim(max_min(grd_test_read.lat_rho))
    saveas(gcf,append("forcing_test_swrad_",datestr(frc_time(t)) ,".jpg"))
    frame = getframe(gcf);
    writeVideo(mv,frame);
end
close(mv)

%% ploting to check
cd(figure_path)
mv = VideoWriter('surf_pressure_check_20220822', 'Motion JPEG AVI');
mv.FrameRate = 5;
open(mv);
for t = 1 : size(frc_time,1)
    disp(append("time : ",datestr(frc_time(t))))
    figure; clf; hold on
    colormap(thermal)
    ti = tiledlayout(1,2); ti.Padding = "compact"; ti.TileSpacing = "tight";
    ax(1) = nexttile; hold on
    mypcolor(NCOM_GRID.Longitude,NCOM_GRID.Latitude,NCOM_PRES.slpres(:,:,t))
    grid_boundary_plot(grd_test_read.lon_rho,grd_test_read.lat_rho,"k",2)
    colorbar; daspect([1 1 1])
    title("NCOM data")

    ax(2) = nexttile; hold on
    mypcolor(grd_test_read.lon_rho,grd_test_read.lat_rho,frc_test_read.Pair(:,:,t))
    colorbar; daspect([1 1 1])
    title("ROMS inital nc file")
    title(ti,append("Atmospheric pressure (mb)",...
        " for time : ",datestr(frc_time(t))))

    clim(ax,[996.5 1001.7]); linkaxes(ax,'xy'); 
    xlim(max_min(grd_test_read.lon_rho))
    ylim(max_min(grd_test_read.lat_rho))
    saveas(gcf,append("forcing_test_pair_",datestr(frc_time(t)) ,".jpg"))
    frame = getframe(gcf);
    writeVideo(mv,frame);
end
close(mv)

%% velocity
u_rho = u2rho(frc_test_read.sustr);   % [2050,2562,128], now matches temp's grid
v_rho = v2rho(frc_test_read.svstr);   % [2050,2562,128], now matches temp's grid
[ROMS_u_out, ROMS_v_out] = vel_rot(u_rho,v_rho, ...
        rad2deg(grd_test_read.angle), 'grid2geo');

NCOM_u_out = NCOM_WIND.stresu;
NCOM_v_out = NCOM_WIND.stresv;

NCOM_WIND_MAG = abs(NCOM_u_out + 1i * NCOM_v_out);
ROMS_WIND_MAG = abs(ROMS_u_out + 1i * ROMS_v_out);

nn = 50;
Lon_plot = NCOM_GRID.Longitude(1:nn:end,1:nn:end);
Lat_plot = NCOM_GRID.Latitude(1:nn:end,1:nn:end);

nn_roms = 163;
Lon_plot_roms = grd_test_read.lon_rho(1:nn_roms:end,1:nn_roms:end);
Lat_plot_roms = grd_test_read.lat_rho(1:nn_roms:end,1:nn_roms:end);

%% ploting to check
cd(figure_path)
mv = VideoWriter('surf_windstress_check_20220822', 'Motion JPEG AVI');
mv.FrameRate = 5;
open(mv);
s = 5;
for t = 1 : size(frc_time,1)
    disp(append("time : ",datestr(frc_time(t))))
    figure; clf; hold on
    colormap(speed)
    ti = tiledlayout(1,2); ti.Padding = "compact"; ti.TileSpacing = "tight";
    ax(1) = nexttile; hold on
    mypcolor(NCOM_GRID.Longitude,NCOM_GRID.Latitude,NCOM_WIND_MAG(:,:,t))

    quiver(Lon_plot,Lat_plot,s*NCOM_u_out(1:nn:end,1:nn:end,t), ...
         s*NCOM_v_out(1:nn:end,1:nn:end,t),0, "Color", "r");

    grid_boundary_plot(grd_test_read.lon_rho,grd_test_read.lat_rho,"k",2)
    colorbar; daspect([1 1 1])
    title("NCOM data")

    ax(2) = nexttile; hold on
    mypcolor(grd_test_read.lon_rho,grd_test_read.lat_rho,ROMS_WIND_MAG(:,:,t))

    quiver(Lon_plot_roms,Lat_plot_roms,s*ROMS_u_out(1:nn_roms:end,1:nn_roms:end,t), ...
        s*ROMS_v_out(1:nn_roms:end,1:nn_roms:end,t),0, "Color", "r");

    colorbar; daspect([1 1 1])
    title("ROMS inital nc file")
    title(ti,append("Magnitude of wind stress (Pa)",...
        " for time : ",datestr(frc_time(t))))

    clim(ax,[0 1]*0.15); linkaxes(ax,'xy'); 
    xlim(max_min(grd_test_read.lon_rho))
    ylim(max_min(grd_test_read.lat_rho))
    saveas(gcf,append("forcing_test_sustr_svstr_",datestr(frc_time(t)) ,".jpg"))
    frame = getframe(gcf);
    writeVideo(mv,frame);
end
close(mv)