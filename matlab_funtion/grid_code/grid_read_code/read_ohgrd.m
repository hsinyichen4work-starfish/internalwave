function hgrd=read_ohgrd(opath,nest)
%       PURPOSE
%	        Reads contents of ohgrd_[nest].A file
%       CALL
%               hgrd=read_ohgrd(opath,nest)
%       INPUT
%               opath,nest = path,nest
%       OUTPUT
%               hgrd.lon, hgrd.lat : longitude & latitude
%               hgrd.dx, hgrd.dy   : spacing
%               hgrd.h             : depth
%               hgrd.ang           : rotation angle
%               hgrd.sea           : list of sea points
%               hgrd.lnd           : list of land points
%       USES
%               hgrd=read_ohgrd(opath,1);
%       HISTORY
%               Version 1       T. Campbell 12/31/08
%-----------------------------

fname=[opath '/ohgrd_' num2str(nest) '.B']; 
fid=fopen(fname);
A=fscanf(fid,'%d %d');
dimx=A(1); disp(dimx)
dimy=A(2); disp(dimy)
clear A
fclose(fid);

n2d=dimx*dimy;          shape2d=[dimx dimy];        order2d=[2 1];

fname=[opath '/ohgrd_' num2str(nest) '.A'];
fid=fopen(fname,'r','ieee-be');

hgrd.lon=permute(reshape(fread(fid,n2d,'float32'),shape2d),order2d);
hgrd.lat=permute(reshape(fread(fid,n2d,'float32'),shape2d),order2d);
hgrd.dx =permute(reshape(fread(fid,n2d,'float32'),shape2d),order2d);
hgrd.dy =permute(reshape(fread(fid,n2d,'float32'),shape2d),order2d);
hgrd.h  =permute(reshape(fread(fid,n2d,'float32'),shape2d),order2d);
hgrd.ang=permute(reshape(fread(fid,n2d,'float32'),shape2d),order2d);

hgrd.sea=find(hgrd.h< -0.01);
hgrd.lnd=find(hgrd.h>=-0.01);

fclose(fid);

