function bathy_interp_figure(grd_300m,grd_100m,path_figure,figure_name)

    mooring_path = '/home/mbui/ModelOutput/NCOM/NOPP_mooring/';
    cd(mooring_path);
    load('Amazon_nopp_mooring_final.mat');

    cd(path_figure);
    figure; clf; hold on
    t = tiledlayout(1,2); ti.Padding = 'tight'; ti.TileSpacing = "compact";
    nexttile; hold on
    pcolor(grd_300m.lon4_deg,grd_300m.lat4_deg, grd_300m.bath4); shading interp; colorbar; daspect([1 1 1])
    scatter(cpies_lon,cpies_lat,[],'r','filled')
    scatter(mooring_lon,mooring_lat,[],'b','filled')
    grid_boundary_plot(grd_100m.lon4_deg,grd_100m.lat4_deg,[0.5 1 0.5]*0.5,1)
    xl = xlim; yl = ylim; clim([-5000 0])
    title('300m roms grid')

    nexttile; hold on
    pcolor(grd_100m.lon4_deg,grd_100m.lat4_deg, grd_100m.bath4); shading interp; colorbar; daspect([1 1 1])
    scatter(cpies_lon,cpies_lat,[],'r','filled')
    scatter(mooring_lon,mooring_lat,[],'b','filled')
    grid_boundary_plot(grd_300m.lon4_deg,grd_300m.lat4_deg,[0.5 1 0.5]*0.5,1)
    xlim(xl); ylim(yl);clim([-5000 0])
    title('100m roms grid')

    saveas(gcf,append(figure_name,".jpg"))
    %saveas(gcf,append(figure_name,".fig"))
end