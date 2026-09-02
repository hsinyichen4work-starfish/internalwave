
if ~strcmp(string('amazon_3day.in'),string(filename))
    movefile('amazon_3day.in', filename);
end

file_content = fileread([new_folder,filename]);
file_content = strrep(file_content, 'EXAMPLE TITLE', title);
file_content = strrep(file_content, 'nt_ex', pad(num2str(time_stepping.NTIMES), 5));
file_content = strrep(file_content, ' dt_ex', pad(num2str(time_stepping.dt), 6));
file_content = strrep(file_content, 'ndt_ex', pad(num2str(time_stepping.NDTFAST),6));

str = strrep(upper(sprintf('%.1e', Scoord.THETA_S)), 'E', 'D');
file_content = strrep(file_content, 'the_s_ex', pad(str, 8));
str = strrep(upper(sprintf('%.1e', Scoord.THETA_B)), 'E', 'D');
file_content = strrep(file_content, 'the_b_ex', pad(str, 8));
str = strrep(upper(sprintf('%.1e', Scoord.hc)), 'E', 'D');
file_content = strrep(file_content, 'hc_ex', pad(str,5));


grid_path = ['/expanse/lustre/projects/uso101/hchen54/input/grid_',fold_tile,'/'];
bry_path = ['/expanse/lustre/projects/uso101/hchen54/input/bry_',fold_tile,'/'];
frc_path = ['/expanse/lustre/projects/uso101/hchen54/input/frc_',fold_tile,'/'];
ini_path = ['/expanse/lustre/projects/uso101/hchen54/input/ini_',fold_tile,'/'];
output_path = ['/expanse/lustre/projects/uso101/hchen54/',fold_name,'/roms',];
mkdir(['/expanse/lustre/projects/uso101/hchen54/',fold_name])

cd '/expanse/lustre/projects/uso101/hchen54/input/'

file_content = strrep(file_content, 'EXAMPLE_grid', [grid_path,input_filenames.grd,'.nc']);
file_content = strrep(file_content, 'EXAMPLE_ini', [ini_path,input_filenames.ini,'.nc']);



fil = dir([input_filenames.frc,'*']);
str = string([frc_path,fil(1).name]);
if length(fil) > 1
    for j = 2 : length(fil)
        str = str + newline + string(['     ',frc_path,fil(j).name]);
    end
end
file_content = strrep(file_content, 'EXAMPLE_frc', str);

fil = dir([input_filenames.bry,'*']);
str = string([bry_path,fil(1).name]);
if length(fil) > 1
    for j = 2 : length(fil)
        str = str + newline + string(['     ',bry_path,fil(j).name]);
    end
end
file_content = strrep(file_content, 'EXAMPLE_bry', str);

file_content = strrep(file_content, 'EXAMPLE_output',output_path);

% Write the modified content back to the file
fid = fopen([new_folder,filename], 'w');
if fid == -1
    error('Could not open file %s for writing.', outfile);
end
fprintf(fid, '%s', char(file_content));
fclose(fid);