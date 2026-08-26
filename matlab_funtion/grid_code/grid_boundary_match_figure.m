cd(path_figure)
balance = cmocean('balance');
figure; clf; hold on
ti = tiledlayout(1,3); ti.Padding = "compact"; ti.TileSpacing = "tight";
colormap(parula)
ax(1) = nexttile; hold on
mypcolor(grd_nc.lon_rho,grd_nc.lat_rho,grd_nc.h_orig);
contour(grd_nc.lon_rho,grd_nc.lat_rho,grd_nc.h_orig,...
    [0 100 500 : 500 : 5000],"color","k");
colorbar; clim([0 5000]); daspect([1 1 1])
title('original')

ax(2) = nexttile; hold on
mypcolor(grd_nc.lon_rho,grd_nc.lat_rho,grd_nc.h);
contour(grd_nc.lon_rho,grd_nc.lat_rho,grd_nc.h,...
    [0 100 500 : 500 : 5000],"color","k");
colorbar; clim([0 5000]); daspect([1 1 1])
title('after match')

ax(3) = nexttile; hold on
mypcolor(grd_nc.lon_rho,grd_nc.lat_rho,grd_nc.h - grd_nc.h_orig);
colorbar; clim([-1 1]*10); daspect([1 1 1])
title('after match - original')
colormap(ax(3), balance);
linkaxes(ax,'xy')
saveas(gcf,append("match_topo_check_",num2str(dx),"_2.fig"))
saveas(gcf,append("match_topo_check_",num2str(dx),"_2.jpg"))