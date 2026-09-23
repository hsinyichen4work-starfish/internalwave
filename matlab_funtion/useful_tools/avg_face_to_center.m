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
    %   STAGGER CONVENTION (verified against NCOM nest-2 data, 2022082200):
    %   uface(i,j) sits on the WEST face of cell (i,j), i.e. between
    %   center(i-1,j) and center(i,j); vface(i,j) sits on the SOUTH face.
    %   Evidence: u(i)==0 at every sea cell i whose west neighbor i-1 is land
    %   (the coastline face), but u(i)~=0 at sea cells whose east neighbor is
    %   land; u(1,:) is 0 everywhere (western domain wall). Same for v in j.
    %   So center(i) = 0.5*(uface(i) + uface(i+1)).
    %
    %   Edge treatment: the last row/column has no east/north face stored,
    %   so it's simply copied from its west/south face.
    %
    %   Pass RAW face values (land/below-bottom faces = 0 as NCOM stores
    %   them), not NaN-masked ones -- a NaN on a coastline face would wipe
    %   out the adjacent wet center. Mask the centers afterwards.

        switch dim
            case 1
                uc = uface;
                uc(1:end-1,:,:,:) = 0.5*(uface(1:end-1,:,:,:) + uface(2:end,:,:,:));
                % uc(end,:,:,:) left as uface(end,:,:,:) -- no east face stored
            case 2
                uc = uface;
                uc(:,1:end-1,:,:) = 0.5*(uface(:,1:end-1,:,:) + uface(:,2:end,:,:));
                % uc(:,end,:,:) left as uface(:,end,:,:) -- no north face stored
            otherwise
                error('avg_face_to_center:badDim', 'dim must be 1 or 2.');
        end
    end
