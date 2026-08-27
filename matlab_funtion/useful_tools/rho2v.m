function var_v = rho2v(var_rho)
% RHO2V  Interpolate ROMS rho-point data onto v points.
%
%   Works for 2D [Mp,Lp] or 3D [Mp,Lp,N] arrays, where Lp = Lv+1
%   (rho shrinks along dim 2 to land on v, same convention as v2rho.m).
%   Every v-point sits exactly between two rho neighbors, so this is a
%   simple average -- no edge copying needed (unlike v2rho, which has to
%   extrapolate at the two edges when going the other direction).
%
% Input:
%   var_rho : [Mp,Lp,(N)] data on rho-points
%
% Output:
%   var_v   : [Mp,Lp-1,(N)] data on v-points
%
% Example:
%   z_at_v_locations = rho2v(z_r);   % put z_r on the v grid

    var_v = 0.5*(var_rho(:,1:end-1,:) + var_rho(:,2:end,:));

end