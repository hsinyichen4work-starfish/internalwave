clear; clc
addpath(genpath('/home/hsinyi/Documents/CODE/matlab_funtion/'));
fod = ["2022082200","2022082300","2022082400"]; % ,
grid_reso = [100, 300];                   % child grid resolution (m) -- 300 or 100

for folder_num = 1 : length(fod)
    for grid_num = 1 : length(grid_reso)
        par_name = char(fod(folder_num));  
        chd_grd_name = ['roms_grd_', num2str(grid_reso(grid_num)), 'm.nc'];

        %% ------------------------------------------------------------------
        %  Paths
        %  ------------------------------------------------------------------
        data_path            = ['/home/mbui/ModelOutput/NCOM/data/', par_name, '/'];
        parent_grid_path     = '/home/mbui/ModelOutput/NCOM/grid/';
        child_grid_path      = '/home/hsinyi/roms_data/grid/';
        initial_output_path  = '/home/hsinyi/roms_data/frc/';
        forcing_file_read    = '/home/hsinyi/roms_data/frc/frc_read_nc/';

        %% ------------------------------------------------------------------
        %  Read grids
        %  ------------------------------------------------------------------
        parent_grid = read_nc_fun([parent_grid_path, 'ohgrd_2.nc']);
        child_grid  = read_nc_fun([child_grid_path, chd_grd_name]);
        % NOTE: child_grid is loaded but not referenced again below.
        % If read_nc_fun loads full 3D fields, this is an expensive read for a
        % 2050x2562x268 grid with no downstream use in THIS script.
        % Confirm whether it's needed, otherwise consider removing this line.

        par_N    = size(parent_grid.zm3, 3);   % number of parent vertical levels

        frc_filename = ['roms_frc_', num2str(grid_reso(grid_num)), 'm_',par_name,'.nc'];
        grdname = [child_grid_path, chd_grd_name];
        frcname = [initial_output_path,frc_filename];
        h2r_create_frc(frcname,grdname);
        frc_nc  = read_nc_fun(frcname);

        % make data nc file that can be read in forcing file
        remake = true;
        [par_grd,parinis,pariniw,parinip] = make_frc_need_nc(par_name,forcing_file_read,remake);

        parent_FLUX = [forcing_file_read, parinis];
        parent_WIND = [forcing_file_read, pariniw];
        parent_PRESS  = [forcing_file_read, parinip];
        parent_G  = [forcing_file_read, par_grd];
        chdgrd = [child_grid_path, chd_grd_name];
        chd_ang   = 'rad';

        ndomx = 3; ndomy = 4;
        % Once, regardless of how many dates/time steps you process:
        limits = h2r_frc_subgrid(parent_G, chdgrd, ndomx, ndomy);

        % Then per date/par_name:
        h2r_make_frc(parent_G, parent_FLUX, parent_WIND, parent_PRESS, ...
                chdgrd, frcname, chd_ang, limits);
    end
end