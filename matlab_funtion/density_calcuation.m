function [rho] = density_calcuation(z,lon,lat,temp,salt)
    for k = 1 : size(z,3)
        p(:,:,k) = gsw_p_from_z(z(:,:,k), lat);
        SA(:,:,k) = gsw_SA_from_SP(salt(:,:,k), p(:,:,k), lon, lat); % still needed: practical -> absolute salinity
    end
    CT = gsw_CT_from_pt(SA, temp(:,:,:));            % temp = potential temp here; no p needed
    rho = gsw_rho(SA, CT, p);                 % still needs p, for the in-situ density itself
end