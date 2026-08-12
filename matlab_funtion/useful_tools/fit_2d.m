function [M] = fit_2d(x,y,z,fitstr)
% z = fillmissing2(z,"natural");
dum = ~isnan(z);
M = fit([reshape(x(dum),[],1), reshape(y(dum),[],1)],reshape(z(dum),[],1),fitstr);