%Read in the flat-files of NCOM output for post-processing
%Jie Yu, NRL, October 22, 2019

%%% path to COAMPS static directory where grid files ohgrd_#.A, ovgrd_#.A are 
path_setup='/home/mbui/ModelOutput/NCOM/grid'; 

%hgrd1=read_ohgrd(path_setup,1); 
hgrd2=read_ohgrd(path_setup,2); 
%hgrd3=read_ohgrd(path_setup,3); 
%vgrd1=read_ovgrdA(path_setup,1); 
vgrd2=read_ovgrdA(path_setup,2);
%vgrd3=read_ovgrdA(path_setup,3);

igrd1=size(hgrd1.lon,2); jgrd1=size(hgrd1.lon,1); 
igrd2=size(hgrd2.lon,2); jgrd2=size(hgrd2.lon,1);
igrd3=size(hgrd3.lon,2); jgrd3=size(hgrd3.lon,1);
lo=size(vgrd1,3)-1; 

hgrd1.lon=hgrd1.lon-360; hgrd2.lon=hgrd2.lon-360; hgrd3.lon=hgrd3.lon-360; 

%%%%%% plot bathy with nests
v=(-3500:500:0);
figure; set(gcf,'Units','inches','Position',[0,10.0,5.5,4.0]);
contourf(hgrd1.lon,hgrd1.lat,hgrd1.h,v);
hold on;

%%%% boundaries of nestB, nestC
plot(hgrd2.lon(1,:),hgrd2.lat(1,:),'r');
plot(hgrd2.lon(end,:),hgrd2.lat(end,:),'r');
plot(hgrd2.lon(:,1),hgrd2.lat(:,1),'r');
plot(hgrd2.lon(:,end),hgrd2.lat(:,end),'r');

plot(hgrd3.lon(1,:),hgrd3.lat(1,:),'r');
plot(hgrd3.lon(end,:),hgrd3.lat(end,:),'r');
plot(hgrd3.lon(:,1),hgrd3.lat(:,1),'r');
plot(hgrd3.lon(:,end),hgrd3.lat(:,end),'r');

%%%% plot vertical layers in a section  
i0=250; h1=squeeze(vgrd1(:,i0,:));
plot(hgrd1.lat(:,i0),h1,'k')

tempKC=273.15;   %conversion between degC and degK

%%%% COAMPS style flat files 
appd='_fcstfld'; 
fld_ssh='seahgt'; fld_tmp='seatmp'; 
fld_uuc='uucurr'; fld_vvc='vvcurr'; fld_wwc='wwcurr'; 

%%%% path to COAMPS work directory where ffout is 
path_ff='/p/work1/jyu/COAMPS/coamps-amz/amazon-nestABC2/ocn/ffout'; 

%%%% read data files
nest=1;
str=['igrd=igrd',num2str(nest),';']; eval(str); 
str=['jgrd=jgrd',num2str(nest),';']; eval(str); 
str=['hgrd=hgrd',num2str(nest),';']; eval(str);
reclen2=igrd*jgrd; reclen3=igrd*jgrd*lo; 
grd_str=strcat( num2str(igrd,'%04d'),'x',num2str(jgrd,'%04d') ); 
sfc_str=strcat('_sfc_000000_000000_',num2str(nest),'o'); 
mod_str=strcat('_mod_000001_00',num2str(lo,'%04d'),'_',num2str(nest),'o'); 
mod_str_w=strcat('_mod_000001_00',num2str(lo+1,'%04d'),'_',num2str(nest),'o');

date='2023123100'; dir=strcat(path_ff,date,'/'); 
hr=12; timed=strcat(num2str(hr,'%04d'),'0000');

%%%%% 2D fields
fld2=fld_ssh; 
file_name=strcat(dir,fld2,sfc_str,grd_str,'_',date,'_',timed,appd); 
fid = fopen(file_name,'r','ieee-be'); 
[tmp,~]=fread(fid,reclen2,'real*4'); fclose(fid); 
ssh= reshape(tmp,igrd,jgrd)'; 

figure; set(gcf,'Units','inches','Position',[0 10 5.5 4.5])
pcolor(hgrd.lon,hgrd.lat,ssh); shading interp; colorbar; daspect([1 1 1]); 

%%%% 3D field 
fld3=fld_tmp; 
file_name=strcat(dir,fld3,mod_str,grd_str,'_',date,'_',timed,appd); 
fid = fopen(file_name,'r','ieee-be'); 
[tmp,~]=fread(fid,reclen3,'real*4'); fclose(fid); 
tmp=tmp-tempKC; seatmp= reshape(tmp,igrd,jgrd,lo); %Keep NCOM form.

sst= squeeze(seatmp(:,:,1))'; 

k=50;
temp_k=squeeze(seatmp(:,:,k))'; 

%%%% plotting
figure; set(gcf,'Units','inches','Position',[0,10.0,5.5,4.0]);
pcolor(hgrd1.lon,hgrd1.lat,sst1); shading interp; colorbar; 
clim([-2 9]); colormap(jet);
hold on;
pcolor(hgrd2.lon,hgrd2.lat,sst2); shading interp; clim([-2,9]);
pcolor(hgrd3.lon,hgrd3.lat,sst3); shading interp; clim([-2,9]);

%%%% vertical velocity 
fld3=fld_wwc; 
file_name=strcat(dir,fld3,mod_str_w,grd_str,'_',date,'_',timed,appd); disp(file_name)
fid = fopen(file_name,'r','ieee-be'); 
[tmp,~]=fread(fid,reclen3,'real*4'); fclose(fid); 
tmp= reshape(tmp,igrd,jgrd,lo); %Keep NCOM form.

k=52; wwc= squeeze(tmp(:,:,k))'; 

%%%%% extract a vertical section, e.g., on nestA
idx1=275;
dpth1=squeeze(vgrd1(idx1,:,:)); 
nn=size(dpth1,1); dpth1c=zeros(nn,lo); hgrd1lon_j=zeros(nn,lo);
for zk=1:lo
  dpth1c(:,zk)=(dpth1(:,zk)+dpth1(:,zk+1))/2; 
  hgrd1lon_j(:,zk)=hgrd1.lon(idx1,:);
end 

temp1_j=squeeze(seatmp1(:,idx1,:)); 
pcolor(hgrd1lon_j,dpth1c,temp1_j); shading interp; colorbar; colormap(jet);
clim([-2 9])









