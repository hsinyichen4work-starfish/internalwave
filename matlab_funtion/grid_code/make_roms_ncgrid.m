child function struct = make_roms_ncgrid(grd_struct,grd_name,mid,rot_ang,dx,nx,ny,smooth_var,grid_path)

    size_x = nx*dx; 
    size_y = ny*dx; 
    
    cd(grid_path)
    delete([grd_name,'.nc'])
    delete('roms_grd.nc')
    make_grid(nx,ny,grd_struct.lon4, grd_struct.lat4, ...
        grd_struct.pn,grd_struct.pm,...
        grd_struct.bath4,grd_struct.ang,size_x,size_y,...
        rot_ang,mid(1), mid(2), grd_struct.lone, grd_struct.late);
    ncwrite('roms_grd.nc', 'xy_flip', 0);
    
    movefile('roms_grd.nc', [grd_name,'.nc']);
    struct = lsmooth_fun([grd_name,'.nc'],smooth_var.rmax,smooth_var.hmin,smooth_var.offset);
end