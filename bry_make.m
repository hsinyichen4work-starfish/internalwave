clear; clc
addpath(genpath('/home/hsinyi/Documents/CODE/matlab_funtion/'));

fod = ["2022082200","2022082300","2022082400"]; % ,
grid_reso = [300];

for folder_num = 1 : length(fod)
    % read file folder
    par_name = char(fod(folder_num));  

    %% path setting
    data_path =['/home/mbui/ModelOutput/NCOM/data/',par_name,'/']; 
    parent_grid_path = '/home/mbui/ModelOutput/NCOM/grid/';
    child_grid_path = '/home/hsinyi/roms_data/grid/';
    boundary_output_path = '/home/hsinyi/roms_data/bry/';
    boundaryfile_read = '/home/hsinyi/roms_data/bry/bry_read_nc/';

    % make data nc file that can be read in boundary file
    remake = false;
    [par_grd,parinie,parinit,pariniu] = make_bry_need_nc(par_name,boundaryfile_read,remake);

    %% general parent/ child grid setting
    pargrd1  = [boundaryfile_read par_grd];
    parent_grid = read_nc_fun(pargrd1);
    Np = size(parent_grid.layer_thickness,3);

    for grid_num = 1 : length(grid_reso)
        
        chd_grd    = ['roms_grd_',num2str(grid_reso(grid_num)),'m.nc'];
        chd_thetas = 6;
        chd_thetab = 0.75;
        chd_hc     = 10;
        if grid_reso(grid_num) == 300
            chd_N      = 128; % 128 for 300m grid and 192 for 100m grid 
        elseif grid_reso(grid_num) == 100
            chd_N      = 192; % 128 for 300m grid and 192 for 100m grid 
        else
            error("bry_make.m : not known vertical grid layer number")
        end

        chd_ang    = 'rad';
        chdscoord  = 'new2008';                 % child 'new' or 'old' type scoord
        chdgrd     = [child_grid_path, chd_grd];


        % make boundary file
        bry_filename    = ['roms_bry_',num2str(grid_reso(grid_num)),'m_',par_name,'.nc']; % bry filename
        %% BOUNDARY FILE setting
        obcflag              = [1 1 1 1];      % open boundaries flag (1=open , [S E N W])
        bry_cycle            =  0;             % 0 means no cycle
        %% create empty boundary file  first
        cd(boundary_output_path)
        delete(bry_filename);
        chdscd.theta_s = chd_thetas; chdscd.theta_b = chd_thetab;
        chdscd.hc      = chd_hc; chdscd.N       = chd_N;
        chdscd.scoord  = chdscoord;
        disp(['Creating boundary file: ' bry_filename]);
        h2r_create_bry(bry_filename,chdgrd,obcflag,chdscd);
        bry_check = read_nc_fun(bry_filename);

        % Get parent subgrid bounds
        disp(' ')
        disp('Get parent subgrids for each open boundary')
        limits = h2r_bry_subgrid(pargrd1,chdgrd,obcflag);

        parent_UV = [boundaryfile_read pariniu];
        parent_TS = [boundaryfile_read parinit];
        parent_E = [boundaryfile_read parinie];
        parent_G  = [boundaryfile_read par_grd];

        %% Determine how many time steps are in the consolidated parent files
        info = ncinfo(parent_E, 'ssh');
        ntimes = info.Size(end);   % last dimension = time
        disp(['Found ' num2str(ntimes) ' time steps in parent files']);

        cd(boundary_output_path)
        %% Loop over every time step, writing each into the matching bry_name slot
        for ii = 1:ntimes
            disp(['--- Processing time step ' num2str(ii) ' of ' num2str(ntimes) ' ---'])
            h2r_bry_hv(parent_G, chdgrd, parent_E, parent_TS, parent_UV, Np, bry_filename, ...
                chdscd, obcflag, limits, ii);
        end

        bry_check = read_nc_fun(bry_filename);

        % fix_time

        MT = ncread(parent_UV, 'MT');   % one value per time step, as written by make_bry_need_vel.m
        t1 = datenum(1900,12,31,0,0,0);
        t2 = datenum(1994,1,1,0,0,0);
        ntimes = numel(MT);
        for tout = 1:ntimes
            ocean_time = MT(tout) + t1 - t2;
            ncwrite(bry_filename, 'bry_time', ocean_time, tout);
        end
        disp(['Rewrote bry_time for ' num2str(ntimes) ' time steps in ' bry_filename]);
        
        %% Quick check
        bry_time_check = ncread(bry_filename, 'bry_time');
        disp(datestr(bry_time_check + t2, 'dd-mm-yyyy HH:MM:SS'))
    end

end