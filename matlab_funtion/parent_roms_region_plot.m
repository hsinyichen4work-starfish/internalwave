function parent_roms_region_plot(path_figure,nest100m,nest300m,figname)

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
    fi = figure(2); clf; hold on
    fi.Position = [256   87   1104   777];
    pcolor(lon,lat,h); shading flat; colorbar
    scatter(cpies_lon,cpies_lat,[],'r','filled')
    scatter(mooring_lon,mooring_lat,[],'b','filled')
    axis equal; 
    grid_boundary_plot(lon,lat,[1 1 1]*0,0.5)
    grid_boundary_plot(lon_nest,lat_nest,[1 1 1]*0.4,1)
    grid_boundary_plot(lon_nest_nest,lat_nest_nest,[1 1 1]*0.6,1.5)
    grid_boundary_plot(nest300m.lon4_deg,nest300m.lat4_deg,[0.5 1 0.5],1)
    grid_boundary_plot(nest100m.lon4_deg,nest100m.lat4_deg,[0.5 1 0.5]*0.5,1)

    legend("bathymetry","cpies","mooring",...
        "2700m NCOM grid","","","","900m NCOM grid","","","","300m NCOM grid","","","",...
        "300 ROMS grid","","","","100 ROMS nested grid","","","")
    saveas(gcf,append(figname,".jpg"))
    saveas(gcf,append(figname,".fig"))
    
end