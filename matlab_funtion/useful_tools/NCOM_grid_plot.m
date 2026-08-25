function [mid,rot_ang] = NCOM_grid_plot(mid_iter,path_figure)

    path_setup='/home/mbui/ModelOutput/NCOM/grid/';
    mooring_path = '/home/mbui/ModelOutput/NCOM/NOPP_mooring';
    
    cd(mooring_path);
    load('Amazon_nopp_mooring_final.mat')

    %%
    cd(path_setup);
    filename = "ohgrd_1.nc";
    lon = ncread(filename,'lon'); lat = ncread(filename,'lat');
    ang = ncread(filename,'ang'); hu = ncread(filename,'hu');
    h = ncread(filename,'h'); mask =  ncread(filename,'mask'); 
    zw_1 = ncread(filename,'zw1'); zm3 = ncread(filename,'zm3');
    zw3 = ncread(filename,'zw3');

    filename = "ohgrd_2.nc";
    lon_nest = ncread(filename,'lon'); lat_nest = ncread(filename,'lat');
    ang_nest = ncread(filename,'ang'); hu_nest = ncread(filename,'hu');
    h_nest = ncread(filename,'h'); mask_nest =  ncread(filename,'mask'); 
    zw_1_nest = ncread(filename,'zw1'); zm3_nest = ncread(filename,'zm3');
    zw3_nest = ncread(filename,'zw3');

    filename = "ohgrd_3.nc";
    lon_nest_nest = ncread(filename,'lon'); lat_nest_nest = ncread(filename,'lat');
    ang_nest_nest = ncread(filename,'ang'); hu_nest_nest = ncread(filename,'hu');
    h_nest_nest = ncread(filename,'h'); mask_nest_nest =  ncread(filename,'mask'); 
    zw_1_nest_nest = ncread(filename,'zw1'); zm3_nest_nest = ncread(filename,'zm3');
    zw3_nest_nest = ncread(filename,'zw3');

    %% 

    %%
    cd(path_figure);

    figure(1); clf; hold on
    pcolor(lon,lat,h); shading flat; colorbar
    scatter(cpies_lon,cpies_lat,[],'r','filled')
    scatter(mooring_lon,mooring_lat,[],'b','filled')
    axis equal; legend("bathymetry","cpies","mooring","AutoUpdate","off")
    grid_boundary_plot(lon,lat,[1 1 1]*0,0.5)
    grid_boundary_plot(lon_nest,lat_nest,[1 1 1]*0.4,1)
    grid_boundary_plot(lon_nest_nest,lat_nest_nest,[1 1 1]*0.6,1.5)

    plot([mooring_lon(1),cpies_lon(end-2)],[mooring_lat(1),cpies_lat(end-2)],"color","g","linewidth",2)

    for j = 1 : mid_iter
        if j == 1
            mid = [midpoints([mooring_lon(1),cpies_lon(end-2)]), midpoints([mooring_lat(1),cpies_lat(end-2)])];
        else
            mid_move = [midpoints([mooring_lon(1),mid(1)]), midpoints([mooring_lat(1),mid(2)])];
            mid = mid_move;
        end
    end
   
    [x,y] = lonlat2xy([mooring_lon(1),cpies_lon(end-2)], ...
        [mooring_lat(1),cpies_lat(end-2)],mid(1),mid(2));
    vec_moring = [-x(1)+x(2),-y(1)+y(2)]; 
    rot_ang = rad2deg(angle(vec_moring(1) + 1i * vec_moring(2)))-90;

    scatter(mid(1),mid(2),[],'k','filled')
    saveas(gcf,"bath_test.jpg")
    saveas(gcf,"bath_test.fig")

    xlim([-49 -40]); ylim([-1 9])
    saveas(gcf,"bath_test_zoomin.jpg")
end