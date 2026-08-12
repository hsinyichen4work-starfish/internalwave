function uc = avg_face_to_center(uface, dim)
    %AVG_FACE_TO_CENTER  Average a staggered (face-point) field onto cell centers.
    %
    %   uc = avg_face_to_center(uface, dim)
    %
    %   INPUTS
    %   ------
    %   uface : velocity field on its native staggered face points, any
    %           shape (e.g. (igrd, jgrd, lo, t) for uucurr/vvcurr read via
    %           read_ncom_flatfile). Array size is NOT reduced by staggering
    %           -- per the Arakawa C-grid convention, face-point arrays are
    %           stored at the same (igrd, jgrd) size as center-point arrays,
    %           just physically offset by half a grid cell.
    %   dim   : which dimension to average across --
    %             1 for uucurr (x-faces -> centers, average along the i/x dim)
    %             2 for vvcurr (y-faces -> centers, average along the j/y dim)
    %
    %   OUTPUT
    %   ------
    %   uc : field averaged onto cell centers, same size as uface.
    %
    %   *** IMPORTANT -- VERIFY THIS ASSUMPTION BEFORE TRUSTING THE OUTPUT ***
    %   This function assumes uface(i,j,...) sits at the face BETWEEN
    %   center(i-1,j) and center(i,j) -- i.e. the "west/south face" stagger
    %   convention (matching ROMS's own u/v-point convention). If NCOM
    %   instead stores uface(i,j,...) at the face between center(i,j) and
    %   center(i+1,j) (the "east/north face" convention), this averaging is
    %   shifted by one full grid cell relative to the correct answer --
    %   not a subtle half-cell error, a full-cell one. This detail isn't
    %   fully documented in the material available here; confirm the actual
    %   convention against NCOM/COAMPS documentation or with Jie Yu before
    %   relying on this for anything beyond a first-pass boundary file.
    %   If it turns out to be the opposite convention, swap which edge gets
    %   the "copy the boundary value" treatment below (i.e. mirror the two
    %   branches in each case).
    %
    %   Edge treatment: the outermost row/column has no interior neighbor to
    %   average with, so it's simply copied rather than extrapolated. This
    %   is a minor approximation only relevant right at the domain edge of
    %   the NCOM data itself (not your ROMS child boundary), so it should
    %   have negligible impact as long as your NCOM subgrid extraction window
    %   (imin/imax/jmin/jmax) doesn't sit exactly on the outermost NCOM edge.
    
        switch dim
            case 1
                uc = uface;
                uc(2:end,:,:,:) = 0.5*(uface(1:end-1,:,:,:) + uface(2:end,:,:,:));
                % uc(1,:,:,:) left as uface(1,:,:,:) -- no interior neighbor
            case 2
                uc = uface;
                uc(:,2:end,:,:) = 0.5*(uface(:,1:end-1,:,:) + uface(:,2:end,:,:));
                % uc(:,1,:,:) left as uface(:,1,:,:) -- no interior neighbor
            otherwise
                error('avg_face_to_center:badDim', 'dim must be 1 or 2.');
        end
    end