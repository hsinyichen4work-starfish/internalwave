function [grd_struct,actual_dx_APPROX,actual_dy_APPROX] = ...
    grid_setting(mid,rot_ang,dx,nx,ny)

    addpath(genpath('/home/hsinyi/Documents/CODE/matlab_funtion'));

    %% making new grid ny easy grid
    size_x = nx*dx;   % = 230,400 m  (230.4 km)
    size_y = ny*dx;   % = 614,400 m  (614.4 km)
    [grd_struct.lon4,grd_struct.lat4,grd_struct.pm,grd_struct.pn, ...
        grd_struct.ang,grd_struct.lone,grd_struct.late] = ...
        easy_grid(nx, ny, size_x, size_y,mid(1),mid(2),rot_ang);

    actual_dx = 1./grd_struct.pm;
    actual_dy = 1./grd_struct.pn;
    actual_dx_APPROX = mean(actual_dx(:))   % should be ≈ 100 m
    actual_dy_APPROX = mean(actual_dy(:))   % should be ≈ 100 m

    %% the easygrid goes in radian--> make it to degeree
    [grd_struct.lon4_deg,grd_struct.lat4_deg] = lonlat_rad2deg(grd_struct.lon4,grd_struct.lat4)
    [grd_struct.lone_deg,grd_struct.late_deg] = lonlat_rad2deg(grd_struct.lone,grd_struct.late)

end