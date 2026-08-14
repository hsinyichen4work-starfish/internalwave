function var_rho = u2rho(var_u)
    % U2RHO  Interpolate ROMS u-point data onto rho points.
    %
    %   Works for 2D [Mu,Lp] or 3D [Mu,Lp,N] arrays, where Mu = Mp-1
    %   (u shrinks along dim 1, same convention as rho2uv_latlon.m).
    %   Interior points are averaged from their two u neighbors; the two
    %   edge rows are just copied from the nearest u point (no second
    %   neighbor to average with there).
    %
    % Input:
    %   var_u   : [Mu,Lp,(N)] data on u-points
    %
    % Output:
    %   var_rho : [Mu+1,Lp,(N)] data on rho-points
    %
    % Example:
    %   temp_at_u_locations = u2rho(u);   % put u on the rho grid
    
        interior = 0.5*(var_u(1:end-1,:,:) + var_u(2:end,:,:));
        var_rho  = cat(1, var_u(1,:,:), interior, var_u(end,:,:));
    
    end