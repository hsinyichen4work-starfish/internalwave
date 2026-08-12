function [u_out, v_out] = vel_rot(u_in, v_in, grdang_deg, direction)
    %ROTATE_NCOM_UV  Rotate velocity components between grid-relative and
    %                true east/north frames.
    %
    %   [u_out, v_out] = rotate_ncom_uv(u_in, v_in, grdang_deg, direction)
    %
    %   INPUTS
    %   ------
    %   u_in, v_in  : velocity components, any shape, as long as their first
    %                 two dimensions (horizontal) match grdang_deg's shape.
    %                 Extra dimensions (z, t) are fine -- MATLAB's implicit
    %                 broadcasting handles them automatically as long as
    %                 grdang_deg has no z/t dimensions (i.e. it's static).
    %   grdang_deg  : grid angle in DEGREES from true east (NCOM's grdang
    %                 convention, same shape as u_in/v_in's horizontal dims)
    %   direction   : 'grid2geo' -- rotate grid-relative components (as read
    %                    directly from NCOM's uucurr/vvcurr, after averaging
    %                    to centers) INTO true east/north components.
    %                    Use this when preprocessing NCOM velocities before
    %                    writing pariniu/pariniv for h2r_bry_hv.m.
    %                 'geo2grid' -- the inverse: rotate true east/north
    %                    components INTO grid-relative components. This is
    %                    the same operation h2r_bry_hv.m itself performs
    %                    using the CHILD grid's angle -- you generally won't
    %                    need to call this yourself unless you're doing your
    %                    own validation/round-trip check.
    %
    %   OUTPUTS
    %   -------
    %   u_out, v_out : rotated velocity components, same shape as inputs.
    %
    %   NOTE ON SIGN CONVENTION
    %   ------------------------
    %   This assumes grdang follows the same convention as ROMS's own
    %   'angle' variable: the angle, measured counterclockwise, between the
    %   grid's local xi-axis and true east. Per your NCOM documentation,
    %   grdang is "zero if the xi faces of a grid cell are parallel to
    %   longitude" -- i.e. zero when the grid is already east/north aligned,
    %   consistent with this convention. If your rotated results look
    %   mirrored/backwards after validation, the most likely cause is a sign
    %   flip in grdang itself (some conventions use clockwise-positive) --
    %   fix by negating grdang_deg before calling this function, not by
    %   changing the formulas below.
    
        ang = deg2rad(grdang_deg);
        c = cos(ang);
        s = sin(ang);
    
        switch lower(direction)
            case 'grid2geo'
                % grid-relative (xi,eta) -> true (east,north)
                u_out = u_in.*c - v_in.*s;
                v_out = u_in.*s + v_in.*c;
            case 'geo2grid'
                % true (east,north) -> grid-relative (xi,eta)
                u_out = u_in.*c + v_in.*s;
                v_out = v_in.*c - u_in.*s;
            otherwise
                error('rotate_ncom_uv:badDirection', ...
                    'direction must be ''grid2geo'' or ''geo2grid''.');
        end
    end