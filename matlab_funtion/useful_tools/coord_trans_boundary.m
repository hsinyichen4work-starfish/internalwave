function [u_rot, v_rot] = coord_trans_boundary(u, v, ang, direction)
    %COORD_TRANS  Rotate ROMS boundary u/v between grid-relative (xi,eta) and
    %             true east/north, automatically handling the u/v staggering
    %             mismatch -- works for any of the four boundaries (N,S,E,W).
    %
    %   [u_rot, v_rot] = coord_trans(u, v, ang, direction)
    %
    %   INPUTS
    %   ------
    %   u, v : arrays with along-boundary points on dimension 1 (e.g.
    %          (along_boundary, depth) after squeezing out time). One of
    %          u/v will typically have ONE FEWER point along dim 1 than the
    %          other -- this is expected (staggered u/v-point convention)
    %          and is handled automatically; you don't need to know in
    %          advance which one is staggered for a given boundary.
    %   ang  : rotation angle at rho points, length must equal the LONGER
    %          of size(u,1) / size(v,1) (i.e. matches zeta's along-boundary
    %          length for that same boundary). Row or column vector, either
    %          is fine.
    %   direction : (optional, default 'grid2geo')
    %          'grid2geo' -- rotate grid-relative (xi,eta) components (as
    %                        stored in the bry file) INTO true east/north.
    %                        Use this to plot real-world current directions.
    %          'geo2grid' -- the inverse: true east/north INTO grid-relative.
    %
    %   OUTPUTS
    %   -------
    %   u_rot, v_rot : rotated components, both at rho-point length
    %                  (i.e. length(ang)) along dimension 1 -- ready to plot
    %                  directly against the same along-boundary coordinate
    %                  you'd use for zeta/temp/salt on that boundary.
    %
    %   EXAMPLE
    %   -------
    %   [ueast_rot, veast_rot] = coord_trans( ...
    %       squeeze(bry_test_read.u_east(:,:,t)), ...
    %       squeeze(bry_test_read.v_east(:,:,t)), ...
    %       out_east.ang);
    %
    %   % Works identically for any boundary -- just swap in that
    %   % boundary's u/v/ang, no need to know which of u/v is staggered:
    %   [usouth_rot, vsouth_rot] = coord_trans( ...
    %       squeeze(bry_test_read.u_south(:,:,t)), ...
    %       squeeze(bry_test_read.v_south(:,:,t)), ...
    %       out_south.ang);
    
        if nargin < 4
            direction = 'grid2geo';
        end
    
        ang = ang(:);          % column, Nrho x 1
        Nrho = numel(ang);
    
        u2 = pad_to_rho(u, Nrho);
        v2 = pad_to_rho(v, Nrho);
    
        c = cos(ang);
        s = sin(ang);
    
        switch lower(direction)
            case 'grid2geo'
                u_rot = u2.*c - v2.*s;
                v_rot = u2.*s + v2.*c;
            case 'geo2grid'
                u_rot = u2.*c + v2.*s;
                v_rot = v2.*c - u2.*s;
            otherwise
                error('coord_trans:badDirection', ...
                    'direction must be ''grid2geo'' or ''geo2grid''.');
        end
    end
    
    function out = pad_to_rho(field, Nrho)
        % If field is already at rho-point length, pass through unchanged.
        % If it's one shorter (staggered u/v-point convention), pad it onto
        % rho points: copy the two edge values, average interior neighbors.
        % This matches the standard ROMS-tools u2rho/v2rho convention.
        n = size(field, 1);
    
        if n == Nrho
            out = field;
        elseif n == Nrho - 1
            sz = size(field);
            sz(1) = Nrho;
            out = zeros(sz);
            out(1,:,:)       = field(1,:,:);
            out(end,:,:)     = field(end,:,:);
            out(2:end-1,:,:) = 0.5*(field(1:end-1,:,:) + field(2:end,:,:));
        else
            error('coord_trans:sizeMismatch', ...
                ['Field has %d rows but ang has %d elements -- expected an ' ...
                 'exact match or exactly one fewer (staggered u/v point). ' ...
                 'Check you passed the right boundary''s ang, or that u/v ' ...
                 'weren''t transposed.'], n, Nrho);
        end
end