function var_rho = center2face(var, dim, extrapolate)
    %UV2RHO Interpolate/extrapolate ROMS u- or v-grid variable onto rho-grid
    %   var_rho = UV2RHO(var, dim) interpolates along dimension DIM (the
    %   staggered dimension, size N) to produce an array with size N+1 along
    %   that dimension, matching the rho-grid.
    %
    %   var_rho = UV2RHO(var, dim, extrapolate) — set extrapolate = false to
    %   just copy edge values instead of linear extrapolation (default true).
    %
    %   Example:
    %       v_rho = uv2rho(v, 2);   % v: (nx, ny-1, nz) -> (nx, ny, nz)
    %       u_rho = uv2rho(u, 1);   % u: (nx-1, ny, nz) -> (nx, ny, nz)
    
        if nargin < 3
            extrapolate = true;
        end
    
        n = size(var, dim);
        sz = size(var);
        sz_out = sz;
        sz_out(dim) = n + 1;
    
        % Move working dim to first dimension for simplicity
        nd = ndims(var);
        perm = [dim, setdiff(1:nd, dim)];
        v = permute(var, perm);
    
        interior = 0.5 * (v(1:end-1, :) + v(2:end, :));  % works after reshape below
        % Reshape to 2D (dim1 x everything else) to make indexing easy, then reshape back
        v2d = reshape(v, n, []);
        interior2d = 0.5 * (v2d(1:end-1, :) + v2d(2:end, :));
    
        rho2d = zeros(n+1, size(v2d, 2));
        rho2d(2:n, :) = interior2d;
    
        if extrapolate
            rho2d(1, :)   = 1.5 * v2d(1, :)   - 0.5 * v2d(2, :);
            rho2d(end, :) = 1.5 * v2d(end, :) - 0.5 * v2d(end-1, :);
        else
            rho2d(1, :)   = v2d(1, :);
            rho2d(end, :) = v2d(end, :);
        end
    
        % Reshape back to full size (with dim first), then undo permute
        out_perm_size = [n+1, sz(perm(2:end))];
        rho = reshape(rho2d, out_perm_size);
    
        inv_perm(perm) = 1:nd;
        var_rho = permute(rho, inv_perm);
    end