function limits = h2r_bry_subgrid(parentgrid,childgrid,obcflag)
%
%   Find lower and upper index in i and j for the minimal
%   parent grid that contains all of the boundary bnd of
%   the child grid.
%
%   (c) 2007,  Jeroen Molemaker
%
%--------------------------------------------------------------

% get topography data from parentgrid
Lonc = ncread(childgrid, 'lon_rho')';
Lonc(Lonc<0) = Lonc(Lonc<0) + 360;
Latc = ncread(childgrid, 'lat_rho')';
lonp = double(ncread(parentgrid, 'Longitude'))';
lonp(lonp<0) = lonp(lonp<0) + 360;
latp = double(ncread(parentgrid, 'Latitude'))';

[Mp,Lp]=size(lonp);
tri_par = delaunay(lonp,latp);

limits = zeros(4,4);

for bnd = 1:4
 if ~obcflag(bnd)
    continue
 end
 if bnd == 1 %% South
   lonc = Lonc(1:2,1:end);
   latc = Latc(1:2,1:end);
 end
 if bnd == 2 %% East
   lonc = Lonc(1:end,end-1:end);
   latc = Latc(1:end,end-1:end);
 end
 if bnd == 3 %% North
   lonc = Lonc(end-1:end,1:end);
   latc = Latc(end-1:end,1:end);
 end
 if bnd == 4 %% West
   lonc = Lonc(1:end,1:2);
   latc = Latc(1:end,1:2);
 end

 t   = squeeze(tsearch(lonp,latp,tri_par,lonc,latc));

% Fix to deal with child points that are outside parent grid (those points should be masked!)
  if (length(t(~isfinite(t)))>0)
    disp('Warning in new_bry_subgrid: outside point(s) detected.');
    [lonc,latc] = fix_outside_child(lonc,latc,t);
    t  = squeeze(tsearch(lonp,latp,tri_par,lonc,latc));
  end

  index       = tri_par(t,:);
  [idxj,idxi] = ind2sub([Mp Lp], index);

  limits(bnd,1)  = min(min(idxi));
  limits(bnd,2)  = max(max(idxi));
  limits(bnd,3)  = min(min(idxj));
  limits(bnd,4)  = max(max(idxj));

  if 0  %% debugging
   i0 = limits(bnd,1);
   i1 = limits(bnd,2);
   j0 = limits(bnd,3);
   j1 = limits(bnd,4);
   lonps= lonp(j0:j1,i0:i1);
   latps= latp(j0:j1,i0:i1);

   figure(bnd)
   plot(lonps,latps,'.k')
   hold on
   plot(lonc,latc,'.r')
   hold off
% error('debugging in bry_subgrid')
 end
end

