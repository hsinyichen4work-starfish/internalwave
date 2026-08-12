function [INPOLY, ONPOLY] = in_rectangular(data_x, data_y, rec_x, rec_y)

poly_x = [rec_x(1) rec_x(2) rec_x(2) rec_x(1)];
poly_y = [rec_y(2) rec_y(2) rec_y(1) rec_y(1)];

[INPOLY, ONPOLY] = inpolygon2d(data_x, data_y, poly_x, poly_y);