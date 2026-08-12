function [grd_struct] = bathy_interp(topo,grd_struct,path_figure)

    path_figure='/home/hsinyi/figure/20260803_grid_test'; 

    cd(path_figure)
    figure; pcolor(topo.lon, topo.lat, topo.Z);
    shading interp; colorbar; daspect([1 1 1])
    title('Merged SRTM15+ tiles')
    saveas(gcf,"check_SRTM15.jpg")
    saveas(gcf,"check_SRTM15.fig")

    %%
    grd_struct.bath4 = interp2(topo.lon, topo.lat, topo.Z, ...
                            grd_struct.lon4_deg,grd_struct.lat4_deg);
    grd_struct.bathe = interp2(topo.lon, topo.lat, topo.Z, ...
                            grd_struct.lone_deg,grd_struct.late_deg);
end