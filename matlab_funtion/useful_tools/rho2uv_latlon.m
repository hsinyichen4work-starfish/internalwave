function [lon_u, lat_u, lon_v, lat_v] = rho2uv_latlon(lon_rho, lat_rho)
    % RHO2UV_LATLON  Compute u- and v-point lon/lat from rho-point lon/lat
    %                on a ROMS Arakawa C-grid.
    %
    %   u-points sit at the midpoint between adjacent rho points along the
    %   dimension that is one shorter in the u array (dim 1 here, based on
    %   your sizes: rho [2050,2562] -> u [2049,2562]).
    %   v-points sit at the midpoint along the dimension that is one shorter
    %   in the v array (dim 2 here: rho [2050,2562] -> v [2050,2561]).
    %
    % Inputs:
    %   lon_rho, lat_rho : [Mp,Lp] rho-point coordinates
    %
    % Outputs:
    %   lon_u, lat_u : [Mp-1, Lp]   u-point coordinates
    %   lon_v, lat_v : [Mp, Lp-1]   v-point coordinates
    
        lon_u = 0.5*(lon_rho(1:end-1,:) + lon_rho(2:end,:));
        lat_u = 0.5*(lat_rho(1:end-1,:) + lat_rho(2:end,:));
    
        lon_v = 0.5*(lon_rho(:,1:end-1) + lon_rho(:,2:end));
        lat_v = 0.5*(lat_rho(:,1:end-1) + lat_rho(:,2:end));
    
    end