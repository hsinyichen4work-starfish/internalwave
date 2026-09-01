function [var_bar,var_prime] = depth_mean_bar_cal(var,thickness,bath)
    var_bar   = sum(var.*thickness,ndims(var))./-bath;  
    var_prime = var - var_bar; 
end