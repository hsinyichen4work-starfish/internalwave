function [var_bar, var_prime] = depth_mean_bar_cal(var, thickness, zdim, kb)
% DEPTH_MEAN_BAR_CAL  Thickness-weighted depth mean and perturbation.
%
%   [var_bar, var_prime] = depth_mean_bar_cal(var, thickness, zdim)
%   [var_bar, var_prime] = depth_mean_bar_cal(var, thickness, zdim, kb)
%
% Works for any of:
%   var,thickness : (x,y,z)    -> zdim = 3
%   var,thickness : (x,y,z,t)  -> zdim = 3
%   var,thickness : (x,z)      -> zdim = 2
%   var,thickness : (x,z,t)    -> zdim = 2
%
% var_bar is the depth-weighted mean, with the vertical dimension
% collapsed to a singleton (so it still broadcasts cleanly against var
% when forming var_prime). kb, if given, is the number of active (wet)
% layers with the same shape as var/thickness but WITHOUT the vertical
% dimension (singleton there).
%
% zdim is REQUIRED: array shape alone can't tell a (x,y,z) array from a
% (x,z,t) array, since both have the same ndims.

if nargin < 3 || isempty(zdim)
    error('depth_mean_bar_cal:zdim', ...
        'zdim (the dimension index of the vertical coordinate) must be specified explicitly.');
end

nd = ndims(thickness);
nz = size(thickness, zdim);

if nargin >= 4 && ~isempty(kb)
    kb(isnan(kb)) = 0;                        % land points: zero active layers
    layer_shape = ones(1, nd);
    layer_shape(zdim) = nz;
    layer_idx = reshape(1:nz, layer_shape);   % broadcasts against kb
    active_mask = layer_idx <= kb;
    var(~active_mask) = 0;
    thickness(~active_mask) = 0;
end

H = sum(thickness, zdim);                      % recomputed from the SAME masked array
var_bar = sum(var .* thickness, zdim) ./ H;     % singleton along zdim
var_prime = var - var_bar;                      % implicit expansion over zdim
end