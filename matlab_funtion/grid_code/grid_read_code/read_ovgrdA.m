function vgrd=read_ovgrdA(opath,nest)
%       PURPOSE
%	        Reads contents of ovgrd_[nest].A file
%       CALL
%               vgrd=read_ovgrdA(opath,nest)
%       INPUT
%               opath,nest = path,nest
%       OUTPUT
%               vgrd.lon, hgrd.lat : longitude & latitude
%               vgrd.dx, hgrd.dy   : spacing
%               vgrd.h             : depth
%       USES
%               hgrd=read_ohgrd(opath,1);
%       HISTORY
%               Version 1       T. Campbell 12/31/08
%-----------------------------

fname=[opath '/ovgrd_' num2str(nest) '.B']; 
fid=fopen(fname);
A=fscanf(fid,'%d %d');
dimx=A(1); disp(dimx)
dimy=A(2); disp(dimy)
dimz=A(3); disp(dimz)
clear A
fclose(fid);

n3d=dimx*dimy*dimz;   shape3d=[dimx dimy dimz];  order3d=[2 1 3];

fname=[opath '/ovgrd_' num2str(nest) '.A'];
fid=fopen(fname,'r','ieee-be');

vgrd =permute(reshape(fread(fid,n3d,'float32'),shape3d),order3d);

%vgrd.sea=find(vgrd.h< -0.01);
%vgrd.lnd=find(vgrd.h>=-0.01);

fclose(fid);

