%% Quick patch: recompute and rewrite bry_time only, no re-interpolation needed

boundaryfile_read = '/home/hsinyi/roms_data/bry/bry_read_nc/';
uv_file  = '2022082200_uv.nc';
bry_file = '/home/hsinyi/roms_data/bry/roms_bry_300m_2022082200.nc';

MT = ncread([boundaryfile_read,uv_file], 'MT');   % one value per time step, as written by make_bry_need_vel.m

t1 = datenum(1900,12,31,0,0,0);
t2 = datenum(1994,1,1,0,0,0);

ntimes = numel(MT);
for tout = 1:ntimes
    ocean_time = MT(tout) + t1 - t2;
    ncwrite(bry_file, 'bry_time', ocean_time, tout);
end

disp(['Rewrote bry_time for ' num2str(ntimes) ' time steps in ' bry_file]);

%% Quick check
bry_time_check = ncread(bry_file, 'bry_time');
disp(datestr(bry_time_check + t2, 'dd-mm-yyyy HH:MM:SS'))