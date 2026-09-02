function [p] = density_pressure_cal(rho_prime, thickness, kb)
    G = 9.81;
    nz = size(rho_prime, ndims(rho_prime));

    if nargin >= 3
        kb(isnan(kb)) = 0;
        if ndims(rho_prime) == 3
            layer_idx = reshape(1:nz, 1, 1, nz);
        elseif ndims(rho_prime) == 2
            layer_idx = reshape(1:nz, 1, nz);
        else
            error("ndim should be 2 or 3")
        end
        active_mask = layer_idx <= kb;
        rho_prime(~active_mask) = 0;
        thickness(~active_mask) = 0;
    end

    p = zeros(size(rho_prime));
    if ndims(rho_prime) == 3
        p(:,:,nz) = G .* rho_prime(:,:,nz) .* thickness(:,:,nz);
        for k = (nz-1):-1:1
            p(:,:,k) = p(:,:,k+1) + G .* rho_prime(:,:,k) .* thickness(:,:,k);
        end
    elseif ndims(rho_prime) == 2
        p(:,nz) = G .* rho_prime(:,nz) .* thickness(:,nz);
        for k = (nz-1):-1:1
            p(:,k) = p(:,k+1) + G .* rho_prime(:,k) .* thickness(:,k);
        end
    else
        error("ndim should be 2 or 3")
    end
end