function [var_bar, var_prime] = depth_mean_bar_cal(var, thickness, kb)
    if nargin < 3
        H = sum(thickness, ndims(thickness));
        var_bar = sum(var.*thickness, ndims(var)) ./ H;
    else
        kb(isnan(kb)) = 0;                      % land points: zero active layers

        nz = size(thickness, ndims(thickness));
        if ndims(thickness) == 3
            layer_idx = reshape(1:nz, 1, 1, nz);
        elseif ndims(thickness) == 2
            layer_idx = reshape(1:nz, 1, nz);
        else
            error('thickness must be 2D or 3D')
        end
        active_mask = layer_idx <= kb;           % broadcasts against kb (nx,ny) or (npts,1)

        var(~active_mask) = 0;
        thickness(~active_mask) = 0;

        H = sum(thickness, ndims(thickness));    % recomputed from the SAME masked array
        var_bar = sum(var.*thickness, ndims(var)) ./ H;
    end
    var_prime = var - var_bar;
end