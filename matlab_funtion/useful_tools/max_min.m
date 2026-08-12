function [M] = max_min(variable)

M = [min(variable,[],"all") max(variable,[],"all")];