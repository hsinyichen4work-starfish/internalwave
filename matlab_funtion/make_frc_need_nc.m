function [par_grd,parinis,pariniw,parinip] = make_frc_need_nc(par_name,forcing_path,remake)
    %MAKE_FRC_NEED_NC  Build the parent NetCDF files needed for h2r_frc_hv.m
    %
    %   [par_grd,parinis,pariniw,parinip] = make_frc_need_nc(par_name,forcing_path,remake)
    %
    %   OUTPUTS
    %   -------
    %   par_grd  : [par_name, '_lthick.nc'] -- Longitude and Latitude.
    %   parinis  : [par_name '_flx.nc'] -- heaflx + salflx + solflx
    %   pariniw  : [par_name '_wnd.nc'] -- stresu + stresv (rotated to
    %              true east/north)
    %   parinip  : [par_name '_pres.nc'] -- slpres

    path_setup = ['/home/mbui/ModelOutput/NCOM/data/',par_name,'/'];
    grid_process_path = '/home/mbui/ModelOutput/NCOM/grid/';

    if nargin < 3
        remake = false;
    end

    % read the grid (same static horizontal grid used for bry/ini)
    hgrd2 = read_ohgrd(grid_process_path,2);
    vgrd2=read_ovgrdA(grid_process_path,2);
    parent_grid = read_nc_fun([grid_process_path ,'ohgrd_2.nc']);

    cd(forcing_path);
    par_grd = [par_name, '_lthick.nc'];
    parinis = [par_name, '_flx.nc'];
    pariniw = [par_name, '_wnd.nc'];
    parinip = [par_name, '_pres.nc'];

    make_g = remake || ~isfile(par_grd);
    make_w = remake || ~isfile(pariniw);
    make_s = remake || ~isfile(parinis);
    make_p = remake || ~isfile(parinip);

    if make_g
        disp(append("create ",par_grd))
        [par_grd] = make_bry_need_grid(hgrd2,vgrd2,par_name,forcing_path);
    end

    if make_w
        disp(append("create ",pariniw))
        [pariniw] = make_frc_need_wind(hgrd2, parent_grid.ang, par_name, path_setup, ...
                forcing_path, parent_grid.mask);
    end
    MT = ncread(pariniw,"MT");

    if make_s
        disp(append("create ",parinis))
        [parinis] = make_frc_need_flux(hgrd2, par_name, path_setup, forcing_path, ...
              parent_grid.mask);
    end
    MTs = ncread(parinis,"MT");

    if make_p
        disp(append("create ",parinip))
        [parinip] = make_frc_need_pres(hgrd2, par_name, path_setup, forcing_path, ...
              parent_grid.mask);
    end
    MTp = ncread(parinip,"MT");
end