function infile_make(filename,new_folder,title,time_stepping,Scoord,fold_tile,input_filenames)

example_folder = '/home/hchen54/myrun/example/';
copyfile([example_folder,'amazon_3day.in'],new_folder)
if ~strcmp(string('amazon_3day.in'),string(filename))
    movefile('amazon_3day.in', filename);
end

file_content = fileread([new_folder,file_name]);
file_content = strrep(file_content, 'EXAMPLE TITLE', title);
file_content = strrep(file_content, 'nt_ex', pad(num2str(time_stepping.NTIMES), 5));
file_content = strrep(file_content, ' dt_ex', pad(num2str(time_stepping.dt), 6));
file_content = strrep(file_content, 'ndt_ex', pad(num2str(time_stepping.NDTFAST),6));

str = strrep(upper(sprintf('%.1e', Scoord.THETA_S)), 'E', 'D')
file_content = strrep(file_content, 'the_s_ex', pad(str, 8));
str = strrep(upper(sprintf('%.1e', Scoord.THETA_B)), 'E', 'D')
file_content = strrep(file_content, 'the_b_ex', pad(str, 8));
str = strrep(upper(sprintf('%.1e', Scoord.hc)), 'E', 'D')
file_content = strrep(file_content, 'hc_ex', pad(str,5));


grid_path = ['/expanse/lustre/projects/uso101/hchen54/input/grid_',fold_tile,'/'];
bry_path = ['/expanse/lustre/projects/uso101/hchen54/input/bry_',fold_tile,'/'];
frc_path = ['/expanse/lustre/projects/uso101/hchen54/input/frc_',fold_tile,'/'];
ini_path = ['/expanse/lustre/projects/uso101/hchen54/input/ini_',fold_tile,'/'];

cd '/expanse/lustre/projects/uso101/hchen54/input/'

file_content = strrep(file_content, 'EXAMPLE_grid', [grid_path,input_filenames.grd,'.nc']);
fil = dir([input_filenames.frc,'*']);
str = string(fil(1).name)
for j = 2 : length(fil)
    str = "First line" + newline + "Second line";
"     "

str = "First line" + newline + "Second line";

file_content = strrep(file_content, 'EXAMPLE_frc', [grid_path,input_filenames.frc,'.nc']);