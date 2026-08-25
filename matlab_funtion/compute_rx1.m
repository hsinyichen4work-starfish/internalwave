function [rx1_max, rx1_field, loc] = compute_rx1(h, theta_s, theta_b, hc, N)
    %COMPUTE_RX1  Estimate ROMS grid stiffness ratio (Haney number, rx1) offline.
    %
    %   [rx1_max, rx1_field, loc] = compute_rx1(h, theta_s, theta_b, hc, N)
    %
    %   Inputs:
    %     h        : 2D bathymetry array at rho-points [m], positive down (e.g. hmin=7, hmax=4780)
    %     theta_s  : surface stretching parameter (0 < theta_s <= 10)
    %     theta_b  : bottom stretching parameter  (0 < theta_b <= 10)
    %     hc       : critical depth [m]
    %     N        : number of vertical rho-layers
    %
    %   Outputs:
    %     rx1_max   : single worst-case rx1 value found anywhere in the grid
    %     rx1_field : 3D array of rx1 values (xi- and eta-direction combined,
    %                 taken as the max of the two at each interior point/layer)
    %     loc       : struct with .i, .j, .k giving the (rho-grid) location of
    %                 the maximum, for locating the problem spot in your grid
    %
    %   Notes:
    %     - Assumes a flat sea surface (zeta = 0), which is the standard
    %       assumption for this kind of pre-run stability check (Shchepetkin &
    %       McWilliams 2005/2009 vertical coordinate). Real zeta is generally
    %       tiny compared to h, so this is an excellent approximation.
    %     - Formula follows Haney (1991) / the standard ROMS rx1 definition:
    %
    %         rx1 = | dz_k + dz_{k-1} | / | sz_k - sz_{k-1} |
    %
    %       where, for a given pair of neighboring columns,
    %         dz_k     = z(i+1,k)   - z(i,k)
    %         dz_{k-1} = z(i+1,k-1) - z(i,k-1)
    %         sz_k     = z(i+1,k)   + z(i,k)
    %         sz_{k-1} = z(i+1,k-1) + z(i,k-1)
    %
    %     - This is a quick offline diagnostic to iterate on grid/hc choices
    %       without needing a full recompile + resubmit + wait-in-queue cycle.
    %       Once you find a setting with acceptable rx1 here, still confirm
    %       with the value ROMS itself prints at actual runtime startup.
    
        [Mp, Lp] = size(h);
    
        % ---- build z at rho-points for every layer, assuming zeta = 0 ----
        z_r = zeros(Mp, Lp, N);
        for k = 1:N
            sigma = (k - N - 0.5) / N;   % rho-point sigma, matches ROMS convention
    
            if theta_s > 0
                Csur = (1 - cosh(theta_s*sigma)) / (cosh(theta_s) - 1);
            else
                Csur = -sigma.^2;
            end
    
            if theta_b > 0
                C = (exp(theta_b*Csur) - 1) / (1 - exp(-theta_b));
            else
                C = Csur;
            end
    
            S = (hc*sigma + h.*C) ./ (hc + h);   % nonlinear transform, methods.html eq.
            z_r(:,:,k) = h .* S;                 % zeta = 0  =>  z = h * S (negative down)
        end
    
        % ---- rx1 in xi-direction (i, i+1 neighbors) ----
        dz_xi = diff(z_r, 1, 2);                 % [Mp, Lp-1, N]   z(i+1,k)-z(i,k)
        sz_xi = z_r(:,1:end-1,:) + z_r(:,2:end,:);
    
        num_xi = abs(dz_xi(:,:,2:end) + dz_xi(:,:,1:end-1));
        den_xi = abs(sz_xi(:,:,2:end) - sz_xi(:,:,1:end-1));
        rx1_xi = num_xi ./ den_xi;               % [Mp, Lp-1, N-1]
    
        % ---- rx1 in eta-direction (j, j+1 neighbors) ----
        dz_eta = diff(z_r, 1, 1);                % [Mp-1, Lp, N]
        sz_eta = z_r(1:end-1,:,:) + z_r(2:end,:,:);
    
        num_eta = abs(dz_eta(:,:,2:end) + dz_eta(:,:,1:end-1));
        den_eta = abs(sz_eta(:,:,2:end) - sz_eta(:,:,1:end-1));
        rx1_eta = num_eta ./ den_eta;            % [Mp-1, Lp, N-1]
    
        % ---- combine: take the max of xi/eta at each common (i,j,k) footprint ----
        Mc = min(size(rx1_xi,1), size(rx1_eta,1));
        Lc = min(size(rx1_xi,2), size(rx1_eta,2));
        Kc = size(rx1_xi,3);
    
        rx1_field = max( rx1_xi(1:Mc,1:Lc,:), rx1_eta(1:Mc,1:Lc,:) );
    
        [rx1_max, idx] = max(rx1_field(:));
        [jm, im, km]   = ind2sub(size(rx1_field), idx);
    
        loc.i = im;
        loc.j = jm;
        loc.k = km;
    
        fprintf('Estimated max rx1 = %.4f  at (i=%d, j=%d, k=%d), h there ~= %.1f m\n', ...
                 rx1_max, im, jm, km, h(jm,im));
    end