function [rho] = density_calcuation(z, lon, lat, temp, salt, zdim)
% DENSITY_CALCUATION  In-situ density from depth, temp (potential), salt.
%
%   rho = density_calcuation(z, lon, lat, temp, salt, zdim)
%
% Works for any of:
%   z,temp,salt : (x,y,z)        single-timestep 3D data      -> zdim = 3
%   z,temp,salt : (x,y,z,t)      multi-timestep 3D data        -> zdim = 3
%   z,temp,salt : (x,z)          single-timestep 2D(x,z) data  -> zdim = 2
%   z,temp,salt : (x,z,t)        multi-timestep 2D(x,z) data   -> zdim = 2
%
% z, temp, salt must all share the same size/shape.
% lon, lat should have the same size as z EXCEPT with no vertical extent
% (and, if desired, a singleton in the time dimension) -- e.g. for
% z = (x,y,z,t), lon/lat can be (x,y) or (x,y,1,1). MATLAB's implicit
% expansion takes care of broadcasting them against the full array.
%
% zdim is REQUIRED. Array shape alone cannot disambiguate, e.g., a 3D
% array could be (x,y,z) or (x,z,t) -- both have ndims == 3 but the
% vertical axis sits in a different position, so it must be stated
% explicitly by the caller.

if nargin < 6 || isempty(zdim)
    error('density_calcuation:zdim', ...
        ['zdim (the dimension index of the vertical coordinate) must ', ...
        'be specified explicitly, e.g. zdim=3 for (x,y,z[,t]) or ', ...
        'zdim=2 for (x,z[,t]).']);
end

nd = ndims(z);
nz = size(z, zdim);
idx = repmat({':'}, 1, nd);

p  = nan(size(z));
SA = nan(size(z));

for k = 1:nz
    idx{zdim} = k;
    zk    = z(idx{:});
    saltk = salt(idx{:});
    slice_shape = size(zk);

    % gsw_p_from_z / gsw_SA_from_SP only accept 2-D (MxN) inputs and
    % do their own (limited) scalar/row/column broadcasting -- they
    % don't understand an N-D slice such as (x,y,1,t). So expand
    % lon/lat to the full slice shape ourselves (plain arithmetic
    % DOES support N-D implicit expansion), then flatten everything
    % to column vectors, which the gsw functions accept trivially.
    lat_full = lat + zeros(slice_shape);
    lon_full = lon + zeros(slice_shape);

    zk_col    = zk(:);
    saltk_col = saltk(:);
    lat_col   = lat_full(:);
    lon_col   = lon_full(:);

    pk_col  = gsw_p_from_z(zk_col, lat_col);
    pk_col = max(pk_col, -1.4); 
    SAk_col = gsw_SA_from_SP(saltk_col, pk_col, lon_col, lat_col);

    p(idx{:})  = reshape(pk_col, slice_shape);
    SA(idx{:}) = reshape(SAk_col, slice_shape);
end

CT  = gsw_CT_from_pt(SA, temp);   % temp = potential temp here; no p needed
rho = gsw_rho(SA, CT, p);         % still needs p, for the in-situ density itself
end