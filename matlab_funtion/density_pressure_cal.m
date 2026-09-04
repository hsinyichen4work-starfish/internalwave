function [p] = density_pressure_cal(rho_prime, thickness, zdim, kb)
% DENSITY_PRESSURE_CAL  Bottom-up hydrostatic pressure integration.
%
%   p = density_pressure_cal(rho_prime, thickness, zdim)
%   p = density_pressure_cal(rho_prime, thickness, zdim, kb)
%
% Works for any of:
%   rho_prime,thickness : (x,y,z)    -> zdim = 3
%   rho_prime,thickness : (x,y,z,t)  -> zdim = 3
%   rho_prime,thickness : (x,z)      -> zdim = 2
%   rho_prime,thickness : (x,z,t)    -> zdim = 2
%
% kb, if given, is the number of active (wet) layers and should have the
% same shape as rho_prime/thickness but WITHOUT the vertical dimension
% (singleton there), e.g. (x,y[,t]) for zdim=3 data. Layers beyond kb are
% zeroed out before integrating (land / below-bottom layers).
%
% zdim is REQUIRED for the same reason as in density_calcuation: shape
% alone can't tell a (x,y,z) array from a (x,z,t) array.

if nargin < 3 || isempty(zdim)
    error('density_pressure_cal:zdim', ...
        'zdim (the dimension index of the vertical coordinate) must be specified explicitly.');
end

G  = 9.81;
nd = ndims(rho_prime);
nz = size(rho_prime, zdim);

if nargin >= 4 && ~isempty(kb)
    kb(isnan(kb)) = 0;
    layer_shape = ones(1, nd);
    layer_shape(zdim) = nz;
    layer_idx = reshape(1:nz, layer_shape);   % broadcasts against kb
    active_mask = layer_idx <= kb;
    rho_prime(~active_mask) = 0;
    thickness(~active_mask) = 0;
end

p = zeros(size(rho_prime));
idx = repmat({':'}, 1, nd);

idx{zdim} = nz;
p(idx{:}) = G .* rho_prime(idx{:}) .* thickness(idx{:});

for k = (nz-1):-1:1
    idxk   = idx; idxk{zdim}   = k;
    idxkp1 = idx; idxkp1{zdim} = k + 1;
    p(idxk{:}) = p(idxkp1{:}) + G .* rho_prime(idxk{:}) .* thickness(idxk{:});
end
end