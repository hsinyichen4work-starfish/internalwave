function vor_psi = vorticity_cal(u, v, pm, pn)
% VORTICITY_CAL  Compute relative vorticity on the ROMS psi grid, for all
%                time steps in u/v, auto-detecting rho-grid vs native-grid
%                inputs at each time step.
%
%   vor_psi = vorticity_cal(u, v, pm, pn)
%
% *** MEMORY NOTE ***
% This function loops over time INTERNALLY, but u and v must already be
% FULLY LOADED into memory before you call it (e.g. u is
% [xi x eta x N x time] all at once). If your full u/v arrays are too
% large to hold in memory (as in your original ~86 GB case), this
% function will NOT help -- you still need to read one time step (or one
% file) at a time from disk and call pmpn2psi/vorticity_cal_fast directly
% in YOUR OWN outer loop instead of loading everything and passing it in
% here. Use this version only when u/v for the time range you want
% genuinely fit in memory at once (e.g. a handful of time steps, or after
% youve already subsetted).
%
% INPUTS
%   u   : u-velocity, EITHER on native u-grid [xi_u x eta_rho x N x time]
%         OR already on rho-grid [xi_rho x eta_rho x N x time] (will be
%         auto-converted back to u-grid via rho2u, per time step).
%   v   : v-velocity, EITHER on native v-grid [xi_rho x eta_v x N x time]
%         OR already on rho-grid [xi_rho x eta_rho x N x time] (will be
%         auto-converted back to v-grid via rho2v, per time step).
%   pm  : [xi_rho x eta_rho] inverse grid spacing in xi  (1/dx), rho-points
%   pn  : [xi_rho x eta_rho] inverse grid spacing in eta (1/dy), rho-points
%
% OUTPUT
%   vor_psi : [xi_u x eta_v x N x time] relative vorticity at psi-points
%
% Example:
%   vor_psi = vorticity_cal(u_all, v_all, pm, pn);   % u_all/v_all already
%                                                      % fully in memory

    rho_sz = size(pn);
    [dx_psi, dy_psi] = pmpn2psi(pm, pn);   % computed once, reused every time step

    nt = size(u, 4);
    nz_u = size(u, 3);
    vor_psi = zeros(size(dx_psi,1), size(dx_psi,2), nz_u, nt, 'like', u);  % preallocate

    for t = 1 : nt
        u_t = u(:,:,:,t);
        v_t = v(:,:,:,t);

        if isequal(size(u_t,1), rho_sz(1)) && isequal(size(u_t,2), rho_sz(2))
            u_t = rho2u(u_t);   % was on rho grid -> convert to native u-grid
        end
        if isequal(size(v_t,1), rho_sz(1)) && isequal(size(v_t,2), rho_sz(2))
            v_t = rho2v(v_t);   % was on rho grid -> convert to native v-grid
        end

        vor_psi(:,:,:,t) = vorticity_cal_fast(u_t, v_t, dx_psi, dy_psi);
    end

end

% ---------------- local helper functions ----------------

function vor_psi = vorticity_cal_fast(u, v, dx_psi, dy_psi)
    dvdx = (v(2:end,:,:,:) - v(1:end-1,:,:,:)) ./ dx_psi;
    dudy = (u(:,2:end,:,:) - u(:,1:end-1,:,:)) ./ dy_psi;
    vor_psi = dvdx - dudy;
end

function [dx_psi, dy_psi] = pmpn2psi(pm, pn)
    % psi point (i,j) is surrounded by 4 rho points: (i,j),(i+1,j),(i,j+1),(i+1,j+1)
    pm_psi = 0.25*(pm(1:end-1,1:end-1) + pm(2:end,1:end-1) + ...
                   pm(1:end-1,2:end)   + pm(2:end,2:end));
    pn_psi = 0.25*(pn(1:end-1,1:end-1) + pn(2:end,1:end-1) + ...
                   pn(1:end-1,2:end)   + pn(2:end,2:end));
    dx_psi = 1./pm_psi;
    dy_psi = 1./pn_psi;
end