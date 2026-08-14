function [Fz, z_out] = roms2z(zr, var, ztarget, mask)
    % ROMS2Z  Interpolate a variable already on a sigma/physical-z grid (zr)
    %         onto fixed target z-levels, given a precomputed depth grid.
    %
    %   Use this version when you already have:
    %     - zr  : physical depths at each sigma level, ascending order
    %             (e.g. from ROMS_zgrid.m or NCOM_zgrid.m), size [N,Mp,Lp]
    %     - var : the variable on that SAME grid/order as zr, size [N,Mp,Lp]
    %
    % Inputs:
    %   zr      : [N,Mp,Lp] physical depth of each sigma level (ascending, bottom->top)
    %   var     : [N,Mp,Lp] variable values, same size/order as zr
    %   ztarget : target z levels, ANY order, e.g. -1:-100:-5000
    %   mask    : (optional) either:
    %               - [Mp,Lp]   2D land mask (1=water,0=land), applied at every
    %                           output level (same as before), OR
    %               - [N,Mp,Lp] 3D native-level mask matching zr/var. Cells
    %                           flagged invalid (0) are excluded from the
    %                           interpolation itself, and the below-seafloor
    %                           cutoff is computed per-column from the deepest
    %                           STILL-VALID native level rather than just
    %                           zr(1,:,:). Use this for NCOM-style data where
    %                           individual bottom cells can be bad independent
    %                           of topography.
    %             If omitted, only below-seafloor points (using zr(1,:,:)) are
    %             masked; nothing is masked for land.
    %
    % Outputs:
    %   Fz    : [Nz,Mp,Lp] variable on the z-grid, NaN below seafloor (+land/bad
    %           cells if mask given)
    %   z_out : the Nz target z-levels, returned in the SAME order as ztarget
    %
    % Example (2D land mask):
    %   zr  = ROMS_zgrid(h, zeta, scoord, 'r');      % [N,Mp,Lp]
    %   Tz  = roms2z(zr, temp, -1:-100:-5000, mask_rho);
    %
    % Example (3D native-level mask, e.g. NCOM bottom-cell flags):
    %   zr  = NCOM_zgrid(NCOM_nc);                   % [N,Mp,Lp]
    %   Tz  = roms2z(zr, temp, -1:-100:-5000, ncom_valid_mask3d);
    %
    %----------------------------------------------------------------------
    
    [N,Mp,Lp] = size(zr);
    
    if ~isequal(size(var), [N Mp Lp])
        error('roms2z: var must be the same size as zr, [N,Mp,Lp]. Permute var before calling if it came straight from ncread (typically [Lp,Mp,N]).');
    end
    
    have3dmask = false;
    if nargin > 3 && ~isempty(mask)
        if isequal(size(mask), [Mp Lp])
            have3dmask = false;
        elseif isequal(size(mask), [N Mp Lp])
            have3dmask = true;
        else
            error('roms2z: mask must be [Mp,Lp] (2D land mask) or [N,Mp,Lp] (3D native-level mask matching zr/var).');
        end
    end
    
    % ---- Build target z-grid, ascending, replicated to every column --------
    z_asc = sort(ztarget(:), 'ascend');
    Nz    = length(z_asc);
    zc    = repmat(reshape(z_asc,Nz,1,1), [1 Mp Lp]);            % [Nz,Mp,Lp]
    
    % ---- If a 3D mask was given, exclude bad native cells before interpolating
    if have3dmask
        var(mask == 0) = NaN;
    end
    
    % ---- Build vertical interpolation operator ------------------------------
    % Av depends only on zr/zc, not on var -- reuse it for other variables
    % (salt, u, v, ...) that share this same zr/mask, instead of rebuilding it.
    Av = get_v_coef(zr, zc);
    
    % ---- Apply ----------------------------------------------------------------
    Fz = reshape(Av * reshape(double(var), N*Mp*Lp, 1), Nz, Mp, Lp);
    
    % ---- Mask below-seafloor points (and land / bad cells, if mask supplied) --
    % get_1d_coef does constant extrapolation past the ends of zr, so without
    % this, levels deeper than the local bottom just repeat the bottom (or
    % deepest valid) value.
    if have3dmask
        zr_valid = zr;
        zr_valid(mask == 0) = NaN;
        zbottom = squeeze(min(zr_valid, [], 1));   % deepest still-valid depth per column (NaN if column fully invalid)
    else
        zbottom = squeeze(zr(1,:,:));              % deepest available data point per column
    end
    
    for k = 1:Nz
        below_bottom = z_asc(k) < zbottom;         % NaN comparisons are false, handled explicitly below
        slice = squeeze(Fz(k,:,:));
        slice(below_bottom) = NaN;
        if have3dmask
            slice(isnan(zbottom)) = NaN;           % fully-invalid columns
        elseif nargin > 3 && ~isempty(mask)
            slice(mask == 0) = NaN;                % 2D land mask case
        end
        Fz(k,:,:) = slice;
    end
    
    % ---- Return in the order the user asked for --------------------------------
    z_out = z_asc;
    if ztarget(1) > ztarget(end)     % user gave descending order, e.g. -1:-100:-5000
        Fz    = flip(Fz,1);
        z_out = flip(z_out);
    end
    
    end