function [p] = density_pressure_cal(rho_prime,thickness)
    G = 9.81;
    p = zeros(size(rho_prime)); nz = size(p,ndims(rho_prime));
    if ndims(rho_prime) == 3
        p(:, : ,nz) = G .* rho_prime(:, :, nz) .* thickness(:, :, nz);
        for k = (nz-1):-1:1
            p(:,:,k) = p(:, :,k+1) + G .* rho_prime(:, :, k) .* thickness(:, :, k);
        end
    elseif ndims(rho_prime) == 2
        p(:,nz) = G .* rho_prime(:, nz) .* thickness(:, nz);
        for k = (nz-1):-1:1
            p(:,k) = p(:,k+1) + G .* rho_prime(:, k) .* thickness(:, k);
        end
    else
        error("ndim should be 2 or 3")
    end
end