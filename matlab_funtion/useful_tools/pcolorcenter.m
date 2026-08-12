function h = pcolorcenter(X,Y,Z)
% Makes a pcolor plot, but with colors centered on each point.
% Assumes the X,Y data grids are regularly spaced

dx1 = diff(X); 
dy1 = (diff(Y'))';

dx1 = [dx1 dx1(end)];
X0 = [X(1,:)-dx1(1,:); X; X(end,:)+dx1(end,:)];
A = diff(X0');
dx2 = [(diff(X0'))', A(end,:)'];
X0 = [X0(:,1)-dx2(:,1)  X0  X0(:,end)+dx2(:,end)];

dy1 = [dy1  dy1(end)];
Y0 = [Y(:,1)-dy1(:,1) Y Y(:,end)+dy1(:,end)];
A = diff(Y0);
dy2 = [diff(Y0) A(end)] ;
Y0 = [Y0(1,:)-dy2(1,:); Y0; Y0(end,:)+dy2(end,:)];


XM = (X0(1:end-1,1:end-1)+X0(2:end,1:end-1)+X0(1:end-1,2:end)+X0(2:end,2:end))/4;
YM = (Y0(1:end-1,1:end-1)+Y0(2:end,1:end-1)+Y0(1:end-1,2:end)+Y0(2:end,2:end))/4;

XM = mean(XM); YM = mean(YM);

Z = [Z NaN*ones(size(Z,1),1)];
Z = [Z; NaN*ones(1,size(Z,2))];

h = pcolor(XM,YM,Z);
