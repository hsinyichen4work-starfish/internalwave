function [par_grd,parinie,parinit,pariniu] = make_bry_need_nc(par_name,boundary_path,remake)

    path_setup =['/home/mbui/ModelOutput/NCOM/data/',par_name,'/']; 
    grid_process_path = '/home/mbui/ModelOutput/NCOM/grid/';

    if nargin < 3
        remake = false;
    end

    %% 
    %%
    % read the grid 
    hgrd2=read_ohgrd(grid_process_path,2); 
    vgrd2=read_ovgrdA(grid_process_path,2);
    parent_grid = read_nc_fun([grid_process_path ,'ohgrd_2.nc']);

    valid_lay = parent_grid.kb;

    cd(boundary_path);
    par_grd = [par_name, '_lthick.nc'];
    parinie = [par_name, '_ssh.nc'];
    parinit = [par_name, '_ts.nc'];
    pariniu = [par_name, '_uv.nc'];

    if ~remake
        if ~isfile(par_grd)
            disp(append("create ",par_grd))
            [par_grd] = make_bry_need_grid(hgrd2,vgrd2,par_name,boundary_path);
        end
        if ~isfile(pariniu)
            disp(append("create ",pariniu))
            [pariniu] = make_bry_need_vel(hgrd2, vgrd2, valid_lay, parent_grid.ang, par_name, path_setup, ...
                    boundary_path, parent_grid.mask);
        end
        if ~isfile(parinie)
            disp(append("create ",parinie))
            [parinie] = make_bry_need_ssh(hgrd2, par_name, path_setup, boundary_path, ...
                  parent_grid.mask);
            MT = ncread(pariniu,"MT");
            nccreate(parinie, 'MT', 'Dimensions', {'time', Inf}, 'Datatype', 'double');
            ncwrite(parinie, 'MT', MT, [1]);
        end
        if ~isfile(parinit)
            disp(append("create ",parinit))
            [parinit] = make_bry_need_temp(hgrd2, vgrd2, valid_lay, par_name, path_setup, ...
                  boundary_path, parent_grid.mask);
            MT = ncread(pariniu,"MT");
            nccreate(parinit, 'MT', 'Dimensions', {'time', Inf}, 'Datatype', 'double');
            ncwrite(parinit, 'MT', MT, [1]);
        end
        
    else
        disp(append("create ",par_grd))
        [par_grd] = make_bry_need_grid(hgrd2,vgrd2,par_name,boundary_path);
        disp(append("create ",parinie))
        [parinie] = make_bry_need_ssh(hgrd2, par_name, path_setup, boundary_path, ...
                    parent_grid.mask);
        disp(append("create ",parinit))
        [parinit] = make_bry_need_temp(hgrd2, vgrd2, valid_lay, par_name, path_setup, ...
                    boundary_path, parent_grid.mask);
        disp(append("create ",pariniu))
        [pariniu] = make_bry_need_vel(hgrd2, vgrd2, valid_lay, parent_grid.ang, par_name, path_setup, ...
                        boundary_path, parent_grid.mask);

        MT = ncread(pariniu,"MT");
        nccreate(parinie, 'MT', 'Dimensions', {'time', Inf}, 'Datatype', 'double');
        ncwrite(parinie, 'MT', MT, [1]);

        nccreate(parinit, 'MT', 'Dimensions', {'time', Inf}, 'Datatype', 'double');
        ncwrite(parinit, 'MT', MT, [1]);
    end

end
    