function struct = read_nc_fun(file_name)
    info = ncinfo(file_name);
    varis= {info.Variables.Name}';
    for j = 1 : length(varis)
        struct.(string(varis(j))) = ncread(file_name,string(varis(j)));
    end
end 


