function var_rho = v2rho(var_v)
    % V2RHO  Interpolate ROMS v-point data onto rho points.
    %
    %   Works for 2D [Mp,Lv] or 3D [Mp,Lv,N] arrays, where Lv = Lp-1
    %   (v shrinks along dim 2, same convention as rho2uv_latlon.m).
    %   Interior points are averaged from their two v neighbors; the two
    %   edge columns are just copied from the nearest v point (no second
    %   neighbor to average with there).
    %
    % Input:
    %   var_v   : [Mp,Lv,(N)] data on v-points
    %
    % Output:
    %   var_rho : [Mp,Lv+1,(N)] data on rho-points
    %
    % Example:
    %   temp_at_v_locations = v2rho(v);   % put v on the rho grid
    
        interior = 0.5*(var_v(:,1:end-1,:) + var_v(:,2:end,:));
        var_rho  = cat(2, var_v(:,1,:), interior, var_v(:,end,:));
    
    end