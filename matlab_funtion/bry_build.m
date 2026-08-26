for folder_num = 1 : length(fod)
    % read file folder
    par_name = char(fod(folder_num));  
    %% path setting
    data_path =[parent_data_path,par_name,'/']; 
    disp(['read data from ',data_path])
    % make data nc file that can be read in boundary file
    remake = false;
    [par_grd,parinie,parinit,pariniu] = make_bry_need_nc(par_name,nc_path_ini_bry,remake);

    %% general parent/ child grid setting
    pargrd1  = [nc_path_ini_bry par_grd];
    pgrid_ncom = read_nc_fun(pargrd1);
    Np = size(pgrid_ncom.layer_thickness,3);

    chdgrd     = [grid_path,grd_name,'.nc'];
    % make boundary file
    bry_filename    = ['roms_bry_',num2str(dx),'m_',par_name,'.nc']; % bry filename

    chdscd.theta_s = chd_thetas; chdscd.theta_b = chd_thetab;
    chdscd.hc      = chd_hc; chdscd.N       = chd_N;
    chdscd.scoord  = chdscoord;
    %% BOUNDARY FILE setting
    obcflag              = [1 1 1 1];      % open boundaries flag (1=open , [S E N W])
    bry_cycle            =  0;             % 0 means no cycle
    %% create empty boundary file  first
    cd(boundary_path)
    delete(bry_filename);
    disp(['Creating boundary file: ' bry_filename]);
    h2r_create_bry(bry_filename,chdgrd,obcflag,chdscd);
    bry_check = read_nc_fun(bry_filename);

    % Get parent subgrid bounds
    disp(' ')
    disp('Get parent subgrids for each open boundary')
    limits = h2r_bry_subgrid(pargrd1,chdgrd,obcflag);

    parent_UV = [nc_path_ini_bry pariniu];
    parent_TS = [nc_path_ini_bry parinit];
    parent_E = [nc_path_ini_bry parinie];
    parent_G  = [nc_path_ini_bry par_grd];

    %% Determine how many time steps are in the consolidated parent files
    info = ncinfo(parent_E, 'ssh');
    ntimes = info.Size(end);   % last dimension = time
    disp(['Found ' num2str(ntimes) ' time steps in parent files']);

    cd(boundary_path)
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