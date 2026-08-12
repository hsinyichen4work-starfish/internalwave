function bathy_intep_figure_section(grd_300m,grd_100m,path_figure)

    mooring_path = '/home/mbui/ModelOutput/NCOM/NOPP_mooring/';
    cd(mooring_path);
    load('Amazon_nopp_mooring_final.mat');

    %% extract the middle of the grid 
    [ny, nx] = size(grd_300m.lon4);
    idx_mid = round(nx/2);   % adjust based on which axis is along-mooring
    [dist, lon_sec, lat_sec, h_sec] = extract_section( ...
        grd_300m.lon4_deg, grd_300m.lat4_deg, grd_300m.bath4, ...
        grd_300m.pm, grd_300m.pn, 'col', idx_mid);

    [dist_moor, mismatch, idx_moor] = match_points_to_section( ...
            lon_sec, lat_sec, dist, mooring_lon, mooring_lat);
    [dist_cpies, mismatch, idx_cpies] = match_points_to_section( ...
            lon_sec, lat_sec, dist, cpies_lon, cpies_lat);

    [ny, nx] = size(grd_100m.lon4);
    idx_mid = round(nx/2);
    [dist_100, lon_sec_100, lat_sec_100, h_sec_100] = extract_section( ...
        grd_100m.lon4_deg, grd_100m.lat4_deg, grd_100m.bath4, ...
        grd_100m.pm, grd_100m.pn, 'col', idx_mid);

    [dist_100start, mismatch, idx_100start] = match_points_to_section( ...
            lon_sec, lat_sec, dist, lon_sec_100(1), lat_sec_100(1));

    %%
    cd(path_figure);

    fi = figure; clf; fi.Position = [1 1 1211 386];
    t = tiledlayout(1,3); ti.Padding = 'tight'; ti.TileSpacing = "compact";
    nexttile; hold on
    pcolor(grd_300m.lon4_deg,grd_300m.lat4_deg, grd_300m.bath4); shading interp; colorbar; daspect([1 1 1])
    scatter(cpies_lon,cpies_lat,[],'r','filled')
    scatter(mooring_lon,mooring_lat,[],'b','filled')
    grid_boundary_plot(grd_100m.lon4_deg,grd_100m.lat4_deg,[0.5 1 0.5]*0.5,1)
    plot(lon_sec, lat_sec,"linewidth",2); clim([-5000 0])
    title('300m roms grid')

    nexttile([1,2]); hold on
    plot(dist, h_sec, 'k', 'LineWidth', 1)
    plot(dist_100 + dist_100start, h_sec_100,"color",[0.5 1 0.5], 'LineWidth', 2,"linestyle","--")
    yl = ylim;
    for j = 1 : length(dist_moor)
        line(dist_moor(j)*[1 1],yl,"color","b");
    end
    for j = 1 : length(dist_cpies)
        line(dist_cpies(j)*[1 1],yl,"color","r");
    end
    xlabel('Along-track distance (km)')
    ylabel('Depth (m)')
    title('Bathymetry cross-section along mooring line')
    grid on
    saveas(gcf,"check_section_side.jpg")
end