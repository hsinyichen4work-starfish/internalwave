function var_u = rho2u(var_rho)
% RHO2U  Interpolate ROMS rho-point data onto u points.
%
%   Works for 2D [Mp,Lp] or 3D [Mp,Lp,N] arrays, where Mp = Mu+1
%   (rho shrinks along dim 1 to land on u, same convention as u2rho.m).
%   Every u-point sits exactly between two rho neighbors, so this is a
%   simple average -- no edge copying needed (unlike u2rho, which has to
%   extrapolate at the two edges when going the other direction).
%
% Input:
%   var_rho : [Mp,Lp,(N)] data on rho-points
%
% Output:
%   var_u   : [Mp-1,Lp,(N)] data on u-points
%
% Example:
%   z_at_u_locations = rho2u(z_r);   % put z_r on the u grid

    var_u = 0.5*(var_rho(1:end-1,:,:) + var_rho(2:end,:,:));

end